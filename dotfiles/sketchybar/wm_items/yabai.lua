return {
    setup = function(opts)
        require("wm_items.yabai_spaces").setup({ opts })
        require("wm_items.yabai_space_creator").setup({ opts })
    end,
}
