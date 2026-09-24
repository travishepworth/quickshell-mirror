pragma Singleton
import QtQuick

/**
 * Turns the config schema into the settings page's layout: categories
 * (`x-category` on each top-level section, in schema order), each made of
 * groups (the section's own fields, then one per nested object), each made
 * of form rows for SchemaField. Keys marked `x-settings: false` are
 * skipped (edited elsewhere: the bar editor, the Themes page, ...).
 * Depends on the schema only, so it's safe as a Repeater model.
 */
QtObject {
  id: root

  // Flattens an object schema into form rows:
  //   { kind: "group", title, path }         for a nested object
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
            "kind": "group",
            "title": prop.title ?? key,
            "path": propPath
          });
          result.push(...children);
        }
      } else if (prop.type === "array" && prop.items?.properties) {
        result.push({
          "kind": "array",
          "title": prop.title ?? key,
          "path": propPath,
          "schema": prop
        });
      } else if (["boolean", "integer", "string"].includes(prop.type) || (prop.type === "array" && prop.items?.type === "string")) {
        result.push({
          "kind": "field",
          "title": prop.title ?? key,
          "path": propPath,
          "schema": prop
        });
      }
    }
    return result;
  }

  // One section as cards: { key, title, description, section, path, rows }.
  // The section's direct values make the first group (titled by the
  // section); each nested object gets its own.
  function groups(schema, sectionKey) {
    const section = schema.properties[sectionKey];
    const sectionTitle = section.title ?? sectionKey;
    const direct = [];
    const nested = [];
    for (const key in section.properties ?? {}) {
      const prop = section.properties[key];
      if (prop["x-settings"] === false)
        continue;
      if (prop.type === "object" && prop.properties) {
        const children = rows(prop, [sectionKey, key]);
        if (children.length > 0)
          nested.push({
            "key": sectionKey + "." + key,
            "title": prop.title ?? key,
            "description": prop.description ?? "",
            "section": sectionTitle,
            "path": [sectionKey, key],
            "rows": children
          });
      } else {
        direct.push(...rows({
          "properties": {
            [key]: prop
          }
        }, [sectionKey]));
      }
    }
    const result = [];
    if (direct.length > 0)
      result.push({
        "key": sectionKey,
        "title": sectionTitle,
        "description": section.description ?? "",
        "section": sectionTitle,
        "path": [sectionKey],
        "rows": direct
      });
    return result.concat(nested);
  }

  // [{ name, sections: [key], links: [page type] }], in schema order.
  // A section without `x-category` is a category of its own.
  function categories(schema) {
    const result = [];
    for (const key in schema?.properties ?? {}) {
      const section = schema.properties[key];
      if (section.type !== "object" || section["x-settings"] === false || groups(schema, key).length === 0)
        continue;
      const name = section["x-category"] ?? section.title ?? key;
      let category = result.find(c => c.name === name);
      if (!category) {
        category = {
          "name": name,
          "sections": [],
          "links": []
        };
        result.push(category);
      }
      category.sections.push(key);
      for (const link of section["x-links"] ?? [])
        if (!category.links.includes(link))
          category.links.push(link);
    }
    return result;
  }
}
