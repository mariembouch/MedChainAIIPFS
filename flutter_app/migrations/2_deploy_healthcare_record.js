const HealthcareRecord = artifacts.require("HealthcareRecord");

module.exports = function (deployer) {
  deployer.deploy(HealthcareRecord);
};
