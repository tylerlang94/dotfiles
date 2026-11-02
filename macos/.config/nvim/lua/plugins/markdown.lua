return {
	-- Markdown Preview
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
		config = function()
			vim.g.mkdp_theme = "dark"
			vim.g.mkdp_browser = "default"
		end,
	},

	-- Optional: better markdown editing
	{
		"preservim/vim-markdown",
		ft = { "markdown" },
		config = function()
			vim.g.vim_markdown_folding_disabled = 0
			vim.g.vim_markdown_new_list_item_indent = 2
			vim.g.vim_markdown_conceal = 0 -- show actual markdown, not icons
		end,
	},

	-- Treesitter: ensure Markdown parsers installed
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"markdown",
				"markdown_inline",
			},
		},
	},
}
