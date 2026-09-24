pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config

/**
 * Settings form generated from the config schema. Every top-level object
 * section becomes a collapsible SchemaSection; nested objects become
 * labelled groups; booleans, integers and strings become switches, spin
 * boxes (with the schema's minimum/maximum), combo boxes (enum or
 * `x-options`; color fields get swatches) and text fields; arrays of
 * objects become an add/remove/reorder list of those fields. Labels and
 * help text come from `title` and `description`. Keys marked
 * `x-settings: false` are skipped (edited elsewhere, e.g. bars in the bar
 * editor, or owned by the overlay's Themes page).
 *
 * Adding a setting to the schema is all it takes for it to appear here.
 */
ColumnLayout {
  id: root

  required property var schema
  required property var config

  // Emitted with the key path (e.g. ["Appearance", "shape", "radius"])
  signal edited(var path, var value)

  spacing: Widget.spacing * 2

  readonly property var sections: Object.keys(schema?.properties ?? {}).filter(key => {
    const section = schema.properties[key];
    return section.type === "object" && section["x-settings"] !== false && rows(section, [key]).length > 0;
  })

  // Flattens an object schema into form rows:
  //   { kind: "group", title, path }   for a nested object
  //   { kind: "field", title, path, schema } for an editable value
  //   { kind: "array", title, path, schema } for an array of objects
  function rows(objectSchema, path) {
    const result = [];
    for (const key in objectSchema.properties ?? {}) {
      const prop = objectSchema.properties[key];
      if (prop["x-settings"] === false)
        continue;
      const propPath = path.concat(key);
      if (prop.type === "object" && prop.properties) {
        const children = rows(prop, propPath);
        if (children.length > 0) {
          result.push({
            kind: "group",
            title: prop.title ?? key,
            path: propPath
          });
          result.push(...children);
        }
      } else if (prop.type === "array" && prop.items?.properties) {
        result.push({
          kind: "array",
          title: prop.title ?? key,
          path: propPath,
          schema: prop
        });
      } else if (["boolean", "integer", "string"].includes(prop.type)) {
        result.push({
          kind: "field",
          title: prop.title ?? key,
          path: propPath,
          schema: prop
        });
      }
    }
    return result;
  }

  function valueAt(path) {
    let value = root.config;
    for (const key of path)
      value = value?.[key];
    return value;
  }

  Repeater {
    model: root.sections

    delegate: SchemaSection {
      id: section
      required property string modelData
      readonly property var sectionSchema: root.schema.properties[modelData]

      title: sectionSchema.title ?? modelData
      description: sectionSchema.description ?? ""
      expanded: false
      Layout.leftMargin: Widget.padding
      Layout.rightMargin: Widget.padding

      Repeater {
        model: root.rows(section.sectionSchema, [section.modelData])

        delegate: SchemaField {
          required property var modelData
          row: modelData
          form: root
        }
      }
    }
  }
}
