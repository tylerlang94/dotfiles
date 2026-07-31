return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",           -- or lazy=false if you prefer
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",        -- ensure this is listed _after_ nvim-cmp
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        -- …
      })
    end,
  },
}

