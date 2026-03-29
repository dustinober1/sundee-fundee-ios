/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: "https://sundeefundee.com",
  generateRobotsTxt: true,
  exclude: ["/api/*", "/dashboard", "/workouts/*", "/programs/*", "/maxes", "/benchmarks/*", "/cycle", "/settings"],
};
