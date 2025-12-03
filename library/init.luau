local HttpService = cloneref(game:GetService('HttpService'))

local Connections = {}
local Config, Fetcher = {}, {}

local Fluent = loadstring(game:HttpGet('https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua'))()

local function save_config()
    if not isfolder(`Amfer`) then
        makefolder(`Amfer`)
    end

    if not isfolder(`Amfer/configs`) then
        makefolder(`Amfer/configs`)
    end

    if not isfile(`Amfer/configs/{game.PlaceId}.json`) then
        writefile(`Amfer/configs/{game.PlaceId}.json`, HttpService:JSONEncode({}))
    end

    for index, value in pairs(Connections) do
        Config[index] = type(value) == 'table' and HttpService:JSONDecode(HttpService:JSONEncode(value)) or value
    end

    pcall(function()
        writefile(`Amfer/configs/{game.PlaceId}.json`, HttpService:JSONEncode(Config))
    end)
end

local function fetcher_config()
    if not isfolder(`Amfer`) or not isfile(`Amfer/configs/{game.PlaceId}.json`) then
        save_config()
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(`Amfer/configs/{game.PlaceId}.json`))
    end)

    if success then
        Fetcher = data

        for index, value in pairs(Fetcher) do
            Connections[index] = value
        end
    else
        Fetcher = {}
    end

    return Fetcher
end

local Window = Fluent:CreateWindow({
    Title = 'Amfer',
    SubTitle = '',
    TabWidth = 107,
    Size = UDim2.fromOffset(440, 315),
    Acrylic = false,
    Theme = 'Darker',
    MinimizeKey = Enum.KeyCode.End
})

local function update(property, value, callback)
    Connections[property] = value
    callback(value)

    save_config()
end

local function create_signal(signal)
    function signal:create_button(button)
        return signal:AddButton({
            title = button.Title or '',
            description = button.Description or '',
            callback = button.Callback or (function() end)
        })
    end

    function signal:create_dialog(dialog)
        return Window:Dialog({
            title = dialog.Title or '',
            content = dialog.Content or '',
            buttons = dialog.Buttons or {}
        })
    end

    function signal:create_toggle(connection, toggle)
        toggle.Flag = toggle.Flag or connection
        toggle.Default = toggle.Default or false
        toggle.Callback = toggle.Callback or (function() end)

        if not fetcher_config()[toggle.Flag] and not Connections[toggle.Flag] then
            Connections[toggle.Flag] = toggle.Default
        end

        toggle.Default = fetcher_config()[toggle.Flag] or Connections[toggle.Flag]
        toggle.Callback = function(value)
            update(toggle.Flag, value, toggle.Callback)
        end

        return signal:AddToggle(connection, {
            title = toggle.Title or '',
            description = toggle.Description or '',
            default = toggle.Default,
            flag = toggle.Flag,
            callback = toggle.Callback
        })
    end

    function signal:create_keybind(connection, keybind)
        keybind.Mode = keybind.Mode or 'Toggle'
        keybind.Default = keybind.Default or 'E'
        keybind.Flag = keybind.Flag or connection
        keybind.Callback = keybind.Callback or (function() end)

        if not fetcher_config()[keybind.Flag] and not Connections[keybind.Flag] then
            Connections[keybind.Flag] = keybind.Default
        end

        keybind.Default = fetcher_config()[keybind.Flag] or Connections[keybind.Flag]
        keybind.Callback = function(value)
            update(keybind.Flag, value, keybind.Callback)
        end

        return signal:AddKeybind(connection, {
            title = keybind.Title or '',
            description = keybind.Description or '',
            mode = keybind.Mode,
            default = keybind.Default,
            flag = keybind.Flag,
            callback = keybind.Callback
        })
    end

    function signal:create_dropdown(connection, dropdown)
        dropdown.Values = dropdown.Values or {}
        dropdown.Multi = dropdown.Multi or false
        dropdown.Default = dropdown.Default or 1
        dropdown.Flag = dropdown.Flag or connection
        dropdown.Callback = dropdown.Callback or (function() end)

        if dropdown.Multi and not fetcher_config()[dropdown.Flag] and not Connections[dropdown.Flag] then
            Connections[dropdown.Flag] = {}

            for _, value in pairs(dropdown.Values) do
                Connections[dropdown.Flag][value] = false
            end
        elseif not fetcher_config()[dropdown.Flag] and not Connections[dropdown.Flag] then
            Connections[dropdown.Flag] = dropdown.Default
        end

        dropdown.Default = fetcher_config()[dropdown.Flag] or Connections[dropdown.Flag]
        dropdown.Callback = function(value)
            update(dropdown.Flag, value, dropdown.Callback)
        end

        return signal:AddDropdown(connection, {
            title = dropdown.Title or '',
            description = dropdown.Description or '',
            options = dropdown.Values,
            multi = dropdown.Multi,
            default = dropdown.Default,
            flag = dropdown.Flag,
            callback = dropdown.Callback
        })
    end

    function signal:create_slider(connection, slider)
        slider.Default = slider.Default or 0
        slider.Flag = slider.Flag or connection
        slider.Callback = slider.Callback or (function() end)

        if not fetcher_config()[slider.Flag] and not Connections[slider.Flag] then
            Connections[slider.Flag] = slider.Default
        end

        slider.Default = fetcher_config()[slider.Flag] or Connections[slider.Flag]
        slider.Callback = function(value)
            update(slider.Flag, value, slider.Callback)
        end

        return signal:AddSlider(connection, {
            title = slider.Title or '',
            description = slider.Description or '',
            min = slider.Min or 0,
            max = slider.Max or 100,
            default = slider.Default,
            rounding = slider.Rounding or 1,
            flag = slider.Flag,
            callback = slider.Callback
        })
    end

    function signal:create_input(connection, input)
        input.Default = input.Default or ''
        input.Flag = input.Flag or connection
        input.Callback = input.Callback or (function() end)

        if not fetcher_config()[input.Flag] and not Connections[input.Flag] then
            Connections[input.Flag] = input.Default
        end

        input.Default = fetcher_config()[input.Flag] or Connections[input.Flag]
        input.Callback = function(value)
            update(input.Flag, value, input.Callback)
        end

        return signal:AddInput(connection, {
            title = input.Title or '',
            description = input.Description or '',
            default = input.Default,
            placeholder = input.Placeholder or '',
            numeric = input.Numeric or false,
            finished = input.Finished or false,
            flag = input.Flag,
            callback = input.Callback
        })
    end

    return signal
end

function Window:create_tab(tab_name, icon)
    local tab = Window:AddTab({ Title = tab_name or '', Icon = icon or '' })
    create_signal(tab)

    function tab:create_section(name)
        local section = tab:AddSection(name or '')
        create_signal(section)

        return section
    end

    return tab
end

function Window:notify(index)
    Fluent:Notify({
        title = index.Title or '',
        content = index.Content or '',
        duration = index.Duration or 3
    })
end

function Window:select_tab(index)
    return Window:SelectTab(index)
end

return Window, Connections
