# Build hair as measured volumes

1. **Calibrate to a real head.** Use the target head mesh or rig. Align a head-centered coordinate frame with known head width, hairline, crown, temples, and nape. Mark a common baseline in each reference. Convert proportional reference measurements to studs using the known head dimension. If the reference only shows the front, use a labeled depth assumption or obtain a side view.
2. **Block the cap and mass.** Sketch the coverage line and part. Build the root cap to follow the skull. Block a few distinct wide volumes over it, such as crown lift, side sweep, and nape. Compare width, depth, and height from front, side, and three-quarter views before carving locks.
3. **Give each lock a direction and cross-section.** Start the centerline at the part or root, carry it around the head, then end with the intended fall or sweep. Build closed rounded or asymmetric cross-sections along the centerline. Keep thickness through the belly. Taper width and thickness toward the tip. A sharp tip can be intentional, but the lock should still have depth and rounded transitions through its body. Avoid making all locks the same size, tip angle, and start point.
4. **Use depth before surface detail.** Layer secondary locks over the main flow and use deliberate overlaps. Sculpt selective separations and add a few accent strands after the large silhouette reads. Check whether dark lines are useful separations or unintended lighting seams. Verify roots and intentional gaps from underneath and in profile.
5. **Fit and inspect.** Use the actual head and supported variants. Check the hairline, temple, behind-ear region, crown, and nape for lift or penetration. Confirm attachment fit after import. Review with neutral light and normal game lighting at close-up and intended gameplay distance.

## Measure without changing the model

Record section ranges in the head's coordinate frame before adjusting the mesh. The included Blender helper measures evaluated mesh extents in explicitly named bands. It accepts centimeter or stud conventions through a supplied unit factor. Use one band per section and select the matching lock or mass if adjacent hair would contaminate the measurement. A band reports bounding dimensions in that band, so use the same definition for the reference targets.

```text
blender -b "<model.blend>" --python-exit-code 1 --python "<skill-dir>/scripts/measure_sections.py" -- "<sections.json>"
```

```json
{"head_frame_object":"HeadFrame","units_to_studs":1,"sections":[{"id":"crown","objects":["MainMass"],"axis":"Z","lo":1.1,"hi":1.7}]}
```

The command prints JSON containing `sections` with measured `actual` vectors. Copy those rows into the skill's checker input and add the independently recorded `expected` and `tolerance` vectors. Map the first, second, and third coordinates to your chosen width, depth, and height convention. The helper only reads the file and prints results.

For lock cross-sections, use a plane perpendicular to the centerline at each station. Report actual width and thickness there. For scalp fit, sample signed clearance along the local scalp normal, compare with the design allowance, and exclude intended gaps such as a lifted fringe.

[Roblox Accessory Fitting Tool](https://create.roblox.com/docs/avatar/accessory-fitting-tool) · [Rigid accessory specifications](https://create.roblox.com/docs/avatar/rigid-accessories/specifications)
