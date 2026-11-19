# Read authored markers in Studio

In the Studio Command Bar, select one saved `KeyframeSequence` in Explorer. Set `track` to the stable actor or effect track used in the cue sheet. Run the following read-only snippet and copy the printed array into the sheet's `actual` field. For more than one clip, concatenate the arrays and apply any intended shot offsets. Read markers from the saved project animation or existing exporter when the source uses a different format.

```lua
local track = "shot-02/actor"
local selection = game:GetService("Selection"):Get()
assert(#selection == 1 and selection[1]:IsA("KeyframeSequence"), "Select one KeyframeSequence")

local actual = {}
for _, keyframe in ipairs(selection[1]:GetKeyframes()) do
    for _, marker in ipairs(keyframe:GetMarkers()) do
        table.insert(actual, {
            track = track,
            cue = marker.Name,
            time = keyframe.Time,
        })
    end
end
if #actual == 0 then
    print("[]")
else
    print(game:GetService("HttpService"):JSONEncode(actual))
end
```

This snapshot reads authored marker times in clip seconds. Use a captured runtime log when you are testing emitted cue timing, speed changes, cancellation, or double playback.

[KeyframeSequence API](https://create.roblox.com/docs/reference/engine/classes/KeyframeSequence) · [Keyframe API](https://create.roblox.com/docs/reference/engine/classes/Keyframe)
