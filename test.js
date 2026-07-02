const hubspot = require('@hubspot/api-client');

const CONTACT_RELATIONSHIP_PROPERTY = 'relationship_type';
const COMPANY_RELATIONSHIP_PROPERTY = 'relationship_types';

const VALID_TYPES = new Set(['Customer', 'Vendor', 'Partner']);

/*
To get the IDs for the association labels you need to call the aAPI and log the response in main
const defs = await hubspotClient.crm.associations.v4.schema.definitionsApi.getAll(
  'contacts',
  'deals'
);

console.log(JSON.stringify(defs, null, 2));
*/
const CONTACT_COMPANY_LABEL_MAP = {
  Customer: 9,
  Vendor: 11,
  Partner: 13,
};

const CONTACT_DEAL_LABEL_MAP = {
  Customer: 20,
  Vendor: 18,
  Partner: 16,
}

function parseRelationshipTypes(rawValue) {
  if (!rawValue) return [];

  return rawValue
    .split(';')
    .map(v => v.trim())
    .filter(v => VALID_TYPES.has(v));
}
async function syncAssociationLabels(
  hubspotClient,
  fromObjectType,
  fromObjectId,
  toObjectType,
  toObjectId,
  desiredRelationshipTypes,
  labelMap
) {
  const managedTypeIds = new Set(Object.values(labelMap));

  const assocResponse =
    await hubspotClient.crm.associations.v4.basicApi.getPage(
      fromObjectType,
      String(fromObjectId),
      toObjectType,
      undefined,
      100
    );

  const existingAssociation = assocResponse.results.find(
    a => String(a.toObjectId) === String(toObjectId)
  );

  const existingTypes =
    existingAssociation?.associationTypes || existingAssociation?.types || [];

  const preservedTypes = existingTypes
    .filter(t => {
      const typeId = Number(t.typeId ?? t.associationTypeId);
      const category = t.category ?? t.associationCategory;

      return !(
        category === 'USER_DEFINED' &&
        managedTypeIds.has(typeId)
      );
    })
    .map(t => ({
      associationCategory: t.category ?? t.associationCategory,
      associationTypeId: Number(t.typeId ?? t.associationTypeId),
    }));

  const desiredTypes = desiredRelationshipTypes
    .filter(type => labelMap[type])
    .map(type => ({
      associationCategory: 'USER_DEFINED',
      associationTypeId: labelMap[type],
    }));

  const finalTypes = [...preservedTypes, ...desiredTypes];

  if (finalTypes.length === 0) return;

  await hubspotClient.crm.associations.v4.basicApi.create(
    fromObjectType,
    String(fromObjectId),
    toObjectType,
    String(toObjectId),
    finalTypes
  );
}

exports.main = async (event, callback) => {
  const hubspotClient = new hubspot.Client({
    accessToken: process.env.SYNC_RELATIONSHIP_ACCESS_TOKEN,
  });

  const contactId = event.object.objectId;

  try {
    // Read enrolled contact relationship type.
    const enrolledContact = await hubspotClient.crm.contacts.basicApi.getById(
      contactId,
      [CONTACT_RELATIONSHIP_PROPERTY]
    );

    const contactRelationshipTypes = parseRelationshipTypes(
      enrolledContact.properties[CONTACT_RELATIONSHIP_PROPERTY]
    );

    const companyAssocResponse =
      await hubspotClient.crm.associations.v4.basicApi.getPage(
        'contacts',
        contactId,
        'companies',
        undefined,
        100
      );

    const associatedCompanyIds = companyAssocResponse.results.map(
      association => association.toObjectId
    );

    if (associatedCompanyIds.length === 0) {
      callback({
        outputFields: {
          status: 'No associated companies found',
        },
      });
      return;
    }

    for (const companyId of associatedCompanyIds) {
      const contactAssocResponse =
        await hubspotClient.crm.associations.v4.basicApi.getPage(
          'companies',
          companyId,
          'contacts',
          undefined,
          100
        );

      const associatedContactIds = contactAssocResponse.results.map(
        association => association.toObjectId
      );

      const companyRelationshipTypes = new Set();

      if (associatedContactIds.length > 0) {
        const batchResponse =
          await hubspotClient.crm.contacts.batchApi.read({
            properties: [CONTACT_RELATIONSHIP_PROPERTY],
            inputs: associatedContactIds.map(id => ({ id: String(id) })),
          });

        for (const contact of batchResponse.results) {
          const values = parseRelationshipTypes(
            contact.properties[CONTACT_RELATIONSHIP_PROPERTY]
          );

          for (const value of values) {
            companyRelationshipTypes.add(value);
          }
        }
      }

      const finalValue = Array.from(companyRelationshipTypes)
        .sort()
        .join(';');
      
      await hubspotClient.crm.companies.basicApi.update(companyId, {
        properties: {
          [COMPANY_RELATIONSHIP_PROPERTY]: finalValue,
        },
      });

      await syncAssociationLabels(
        hubspotClient,
        'contacts',
        contactId,
        'companies',
        companyId,
        contactRelationshipTypes,
        CONTACT_COMPANY_LABEL_MAP
      );
      
      const dealAssocResponse =
      await hubspotClient.crm.associations.v4.basicApi.getPage(
        'contacts',
        String(contactId),
        'deals',
        undefined,
        100
      );

      const associatedDealIds = dealAssocResponse.results.map(
        association => association.toObjectId
      );

      for (const dealId of associatedDealIds) {
        await syncAssociationLabels(
          hubspotClient,
          'contacts',
          contactId,
          'deals',
          dealId,
          contactRelationshipTypes,
          CONTACT_DEAL_LABEL_MAP
        );
      }
  
    }

    callback({
      outputFields: {
        status: 'Company relationship types recalculated and association labels updated',
        companies_updated: associatedCompanyIds.length,
        contact_relationship_types: contactRelationshipTypes.join(';'),
      },
    });
  } catch (error) {
    console.error(error);

    callback({
      outputFields: {
        status: 'Error',
          error_message: error.message,

      },
    });
  }
};
