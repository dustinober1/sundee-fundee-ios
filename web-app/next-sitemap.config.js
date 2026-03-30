/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: "https://sundeefundee.com",
  generateRobotsTxt: true,
  exclude: ["/api/*", "/admin/*", "/dashboard", "/workouts/*", "/programs/*", "/maxes", "/benchmarks/*", "/cycle", "/settings"],
};
