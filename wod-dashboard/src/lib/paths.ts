import path from "path";

// process.cwd() returns wod-dashboard/ when running `npm run dev`
const projectRoot = path.resolve(process.cwd(), "..");

export const WODS_JSON_PATH = path.join(projectRoot, "SundeeFundee/Resources/WODs/wods.json");
export const PROGRAMS_JSON_PATH = path.join(projectRoot, "SundeeFundee/Resources/Programs/programs.json");
export const BENCHMARKS_JSON_PATH = path.join(projectRoot, "SundeeFundee/Resources/Benchmarks/benchmarks.json");
export const PUBLISH_STATUS_PATH = path.join(process.cwd(), "publish-status.json");
