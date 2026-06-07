module.exports = {
  default: {
    paths: ['tests/features/**/*.feature'],
    require: ['tests/support/**/*.js', 'tests/steps/**/*.js'],
    format: [
      'progress',
      'html:reports/cucumber-report.html',
      'json:reports/cucumber-report.json',
      'junit:reports/cucumber-junit.xml'
    ],
    parallel: 1,
    timeout: 90_000
  }
};
