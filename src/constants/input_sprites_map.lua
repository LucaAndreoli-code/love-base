--[[
    Input Sprite Mapping

    Maps LÖVE input names to sprite file basenames.
    Used by InputPrompts to display the correct icon.
]]

return {
    keyboard = {
        -- Letters
        a = "keyboard_a",
        b = "keyboard_b",
        c = "keyboard_c",
        d = "keyboard_d",
        e = "keyboard_e",
        f = "keyboard_f",
        g = "keyboard_g",
        h = "keyboard_h",
        i = "keyboard_i",
        j = "keyboard_j",
        k = "keyboard_k",
        l = "keyboard_l",
        m = "keyboard_m",
        n = "keyboard_n",
        o = "keyboard_o",
        p = "keyboard_p",
        q = "keyboard_q",
        r = "keyboard_r",
        s = "keyboard_s",
        t = "keyboard_t",
        u = "keyboard_u",
        v = "keyboard_v",
        w = "keyboard_w",
        x = "keyboard_x",
        y = "keyboard_y",
        z = "keyboard_z",

        -- Numbers
        ["0"] = "keyboard_0",
        ["1"] = "keyboard_1",
        ["2"] = "keyboard_2",
        ["3"] = "keyboard_3",
        ["4"] = "keyboard_4",
        ["5"] = "keyboard_5",
        ["6"] = "keyboard_6",
        ["7"] = "keyboard_7",
        ["8"] = "keyboard_8",
        ["9"] = "keyboard_9",

        -- Arrows
        up = "keyboard_arrow_up",
        down = "keyboard_arrow_down",
        left = "keyboard_arrow_left",
        right = "keyboard_arrow_right",

        -- Modifiers
        space = "keyboard_space",
        ["return"] = "keyboard_return",
        escape = "keyboard_escape",
        tab = "keyboard_tab",
        backspace = "keyboard_backspace",
        lshift = "keyboard_shift",
        rshift = "keyboard_shift",
        lctrl = "keyboard_ctrl",
        rctrl = "keyboard_ctrl",
        lalt = "keyboard_alt",
        ralt = "keyboard_alt",

        -- Function keys
        f1 = "keyboard_f1",
        f2 = "keyboard_f2",
        f3 = "keyboard_f3",
        f4 = "keyboard_f4",
        f5 = "keyboard_f5",
        f6 = "keyboard_f6",
        f7 = "keyboard_f7",
        f8 = "keyboard_f8",
        f9 = "keyboard_f9",
        f10 = "keyboard_f10",
        f11 = "keyboard_f11",
        f12 = "keyboard_f12",
    },

    xbox = {
        -- Face buttons
        a = "xbox_button_color_a",
        b = "xbox_button_color_b",
        x = "xbox_button_color_x",
        y = "xbox_button_color_y",

        -- System buttons
        start = "xbox_button_start",
        back = "xbox_button_back",
        guide = "xbox_guide",

        -- Bumpers and triggers
        leftshoulder = "xbox_lb",
        rightshoulder = "xbox_rb",
        lefttrigger = "xbox_lt",
        righttrigger = "xbox_rt",

        -- Sticks
        leftstick = "xbox_stick_l_press",
        rightstick = "xbox_stick_r_press",
        leftstick_left = "xbox_stick_l_left",
        leftstick_right = "xbox_stick_l_right",
        leftstick_up = "xbox_stick_l_up",
        leftstick_down = "xbox_stick_l_down",
        rightstick_left = "xbox_stick_r_left",
        rightstick_right = "xbox_stick_r_right",
        rightstick_up = "xbox_stick_r_up",
        rightstick_down = "xbox_stick_r_down",

        -- D-pad
        dpup = "xbox_dpad_up",
        dpdown = "xbox_dpad_down",
        dpleft = "xbox_dpad_left",
        dpright = "xbox_dpad_right",
    },

    -- Mouse (sprites are in keyboard folder)
    mouse = {
        [1] = "mouse_left",
        [2] = "mouse_right",
        [3] = "mouse_scroll", -- middle button
    },
}
