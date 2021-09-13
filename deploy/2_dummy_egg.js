const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"

module.exports = async ({
    deployments,
    getNamedAccounts,
  }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts()

    await deploy('Egg', {
      from: deployer,
      args:[
        ADDRESS_ZERO,
        [ADDRESS_ZERO, ADDRESS_ZERO],
        "test"
      ]
    });
  };