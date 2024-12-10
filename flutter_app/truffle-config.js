module.exports = { 
  networks: { 
    development: { 
    host: "127.0.0.1",	 // Localhost (default: none) 
    port: 7545,		 // Standard Ethereum port (default: none) 
    network_id: "1337",	 // Any network (default: none) 
    }, 
  }, 
    contracts_build_directory: "./assets/src/artifacts/", 
    
  // Configure your compilers 
  compilers: { 
    solc: {	 
      version: "^0.8.0", // Use Solidity 0.8.x

    
    // See the solidity docs for advice 
    // about optimization and evmVersion 
      optimizer: { 
      enabled: false, 
      runs: 200 
      }, 
      evmVersion: "byzantium"
    } 
  } 
  }; 
  