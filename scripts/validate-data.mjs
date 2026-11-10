import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const dataRoot = path.join(root, "data");
const errors = [];
const warnings = [];

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });
}

function rel(file) {
  return path.relative(root, file).replaceAll("\\", "/");
}

function checkUnique(items, key, label, file) {
  const seen = new Set();
  for (const item of items ?? []) {
    const value = item?.[key];
    if (value == null) continue;
    if (seen.has(value)) errors.push(`${file}: duplicate ${label} ${value}`);
    seen.add(value);
  }
}

function checkTables(value, file, trail = "$") {
  if (!value || typeof value !== "object") return;
  if (Array.isArray(value.columns) && Array.isArray(value.rows)) {
    value.rows.forEach((row, index) => {
      if (!Array.isArray(row)) {
        errors.push(`${file}:${trail}.rows[${index}] is not an array`);
      } else if (row.length !== value.columns.length) {
        errors.push(
          `${file}:${trail}.rows[${index}] has ${row.length} cells; expected ${value.columns.length}`,
        );
      }
    });
  }
  if (Array.isArray(value)) {
    value.forEach((item, index) => checkTables(item, file, `${trail}[${index}]`));
  } else {
    Object.entries(value).forEach(([key, child]) =>
      checkTables(child, file, `${trail}.${key}`),
    );
  }
}

const jsonFiles = walk(dataRoot).filter((file) => file.endsWith(".json"));
const parsed = new Map();
for (const file of jsonFiles) {
  try {
    const value = JSON.parse(fs.readFileSync(file, "utf8"));
    parsed.set(rel(file), value);
    checkTables(value, rel(file));
  } catch (error) {
    errors.push(`${rel(file)}: invalid JSON: ${error.message}`);
  }
}

const manifest = parsed.get("data/manifest.json");
checkUnique(manifest?.datasets, "id", "manifest dataset id", "data/manifest.json");
for (const dataset of manifest?.datasets ?? []) {
  const absolute = path.join(root, dataset.path);
  if (!fs.existsSync(absolute)) {
    errors.push(`data/manifest.json: missing dataset path ${dataset.path}`);
  }
}

const sources = parsed.get("data/sources.json");
checkUnique(sources?.sources, "id", "source id", "data/sources.json");

const registry = parsed.get("data/shoe/brand/registry.json");
checkUnique(registry?.brands, "id", "brand id", "data/shoe/brand/registry.json");
for (const brand of registry?.brands ?? []) {
  const paths = brand.datasetPaths ?? (brand.datasetPath ? [brand.datasetPath] : []);
  for (const datasetPath of paths) {
    if (!fs.existsSync(path.join(root, datasetPath))) {
      errors.push(`brand ${brand.id}: missing dataset ${datasetPath}`);
    }
  }
}

const brandFiles = [...parsed.entries()].filter(
  ([file, value]) =>
    file.startsWith("data/shoe/brand/") &&
    file !== "data/shoe/brand/registry.json" &&
    value.productionUse === true,
);
const adultBrands = new Set();
const childBrands = new Set();
for (const [, value] of brandFiles) {
  const audience = String(value.audience ?? "");
  const brandId = value.brandId;
  if (!brandId) {
    errors.push(`${value.brand ?? "unknown brand"}: missing brandId`);
    continue;
  }
  if (audience.includes("adult")) adultBrands.add(brandId);
  if (audience === "kids" || audience === "toddlers") childBrands.add(brandId);
}

const targets = registry?.minimumLaunchTarget ?? {};
if (adultBrands.size < (targets.brandsWithAdultOfficialRows ?? 0)) {
  errors.push(
    `adult brand coverage ${adultBrands.size} is below target ${targets.brandsWithAdultOfficialRows}`,
  );
}
if (childBrands.size < (targets.brandsWithChildOfficialRows ?? 0)) {
  errors.push(
    `child brand coverage ${childBrands.size} is below target ${targets.brandsWithChildOfficialRows}`,
  );
}

const sourceAnomalies = brandFiles.flatMap(([file, value]) =>
  (value.sourceAnomalies ?? []).map((anomaly) => ({ file, ...anomaly })),
);
for (const anomaly of sourceAnomalies) {
  warnings.push(
    `${anomaly.file}: excluded source anomaly ${anomaly.field}=${anomaly.sourceDisplayedValue}`,
  );
}

const clothingRegistry = parsed.get("data/clothing/brand/registry.json");
checkUnique(
  clothingRegistry?.brands,
  "id",
  "clothing brand id",
  "data/clothing/brand/registry.json",
);
for (const brand of clothingRegistry?.brands ?? []) {
  for (const datasetPath of brand.datasetPaths ?? []) {
    if (!fs.existsSync(path.join(root, datasetPath))) {
      errors.push(`clothing brand ${brand.id}: missing dataset ${datasetPath}`);
    }
  }
}

const clothingFiles = [...parsed.entries()].filter(
  ([file, value]) =>
    file.startsWith("data/clothing/brand/") &&
    file !== "data/clothing/brand/registry.json" &&
    value.productionUse === true,
);
const clothingAdultMenBrands = new Set();
const clothingAdultWomenBrands = new Set();
const clothingKidsBrands = new Set();
const clothingCategories = new Set();
const clothingMeasurements = new Set();
const clothingSourceExclusions = [];

function recordClothingColumns(columns = []) {
  for (const column of columns) {
    const normalized = String(column).toLowerCase();
    if (normalized.includes("chest")) clothingMeasurements.add("chest_or_bust");
    if (normalized.includes("bust")) clothingMeasurements.add("chest_or_bust");
    if (normalized.includes("waist")) clothingMeasurements.add("waist");
    if (normalized.includes("hip")) clothingMeasurements.add("hip");
  }
}

for (const [file, value] of clothingFiles) {
  const audience = String(value.audience ?? "");
  const category = String(value.category ?? "");
  const brandId = value.brandId;
  if (!brandId) {
    errors.push(`${file}: missing brandId`);
    continue;
  }
  if (audience === "adult_men") clothingAdultMenBrands.add(brandId);
  if (audience === "adult_women") clothingAdultWomenBrands.add(brandId);
  if (["kids", "boys", "girls"].includes(audience)) clothingKidsBrands.add(brandId);
  if (audience === "adult") {
    for (const segment of value.segments ?? []) {
      if (String(segment.id).startsWith("men_")) clothingAdultMenBrands.add(brandId);
      if (String(segment.id).startsWith("women_")) clothingAdultWomenBrands.add(brandId);
    }
  }

  if (category.includes("top")) clothingCategories.add("tops");
  if (category.includes("bottom")) clothingCategories.add("bottoms");
  if (["kids", "boys", "girls"].includes(audience) || category === "apparel") {
    clothingCategories.add("kids");
  }
  for (const segment of value.segments ?? []) {
    if (String(segment.id).includes("top")) clothingCategories.add("tops");
    if (String(segment.id).includes("bottom")) clothingCategories.add("bottoms");
    recordClothingColumns(segment.columns);
  }
  recordClothingColumns(value.columns);

  for (const exclusion of value.excludedSourceValues ?? []) {
    clothingSourceExclusions.push({ file, ...exclusion });
    warnings.push(
      `${file}: excluded source value ${exclusion.segment ?? "unknown"}.${exclusion.field}=${exclusion.sourceDisplayed}`,
    );
  }
}

const clothingTargets = clothingRegistry?.minimumLaunchTarget ?? {};
for (const [label, actual, expected] of [
  ["adult men clothing brand", clothingAdultMenBrands.size, clothingTargets.brandsWithAdultMen ?? 0],
  ["adult women clothing brand", clothingAdultWomenBrands.size, clothingTargets.brandsWithAdultWomen ?? 0],
  ["kids clothing brand", clothingKidsBrands.size, clothingTargets.brandsWithKids ?? 0],
]) {
  if (actual < expected) errors.push(`${label} coverage ${actual} is below target ${expected}`);
}
for (const category of clothingTargets.requiredCategories ?? []) {
  if (!clothingCategories.has(category)) {
    errors.push(`clothing category coverage is missing ${category}`);
  }
}
for (const measurement of clothingTargets.requiredMeasurements ?? []) {
  if (!clothingMeasurements.has(measurement)) {
    errors.push(`clothing measurement coverage is missing ${measurement}`);
  }
}

const report = {
  ok: errors.length === 0,
  parsedJsonFiles: parsed.size,
  manifestDatasets: manifest?.datasets?.length ?? 0,
  officialAdultBrandCoverage: [...adultBrands].sort(),
  officialChildBrandCoverage: [...childBrands].sort(),
  sourceAnomalies: sourceAnomalies.length,
  clothingAdultMenBrandCoverage: [...clothingAdultMenBrands].sort(),
  clothingAdultWomenBrandCoverage: [...clothingAdultWomenBrands].sort(),
  clothingKidsBrandCoverage: [...clothingKidsBrands].sort(),
  clothingCategoryCoverage: [...clothingCategories].sort(),
  clothingMeasurementCoverage: [...clothingMeasurements].sort(),
  clothingSourceExclusions: clothingSourceExclusions.length,
  warnings,
  errors,
};

console.log(JSON.stringify(report, null, 2));
process.exitCode = report.ok ? 0 : 1;
