import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class BlockchainService {
  final String rpcUrl = 'http://127.0.0.1:7545'; // Ganache RPC URL
  final String contractAddress =
      '0xb41401ECc7Ee45072E2057558622a7d0833Cd6BC'; // Replace with your deployed contract address
  final String privateKey =
      '0x70807b05e02e474acacab6c24e7a1db686b1ad6e0127ca2fbe6b58a09a09af71';
  late final Web3Client _client;
  late final Credentials _credentials;
  late final EthereumAddress _contractAddr;
  late final DeployedContract _contract;

  BlockchainService() {
    // Initialize the Web3 client and credentials
    _client = Web3Client(rpcUrl, Client());
    _credentials = EthPrivateKey.fromHex(privateKey);
    _contractAddr = EthereumAddress.fromHex(contractAddress);

    // Initialize the contract
    _initializeContract();
  }

  void _initializeContract() {
    // Define the ABI of the contract
    const abi = '''
      [
        {"inputs":[{"internalType":"string","name":"_username","type":"string"},{"internalType":"string","name":"_password","type":"string"}],"name":"registerUser","outputs":[],"stateMutability":"nonpayable","type":"function"},
        {"inputs":[{"internalType":"string","name":"_username","type":"string"},{"internalType":"string","name":"_password","type":"string"}],"name":"authenticate","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
      ]
    ''';

    // Parse the ABI and associate it with the contract address
    _contract = DeployedContract(
      ContractAbi.fromJson(
          abi, 'Login'), // Replace 'Login' with the name of your contract
      _contractAddr,
    );
  }

  /// Registers a user by calling the `registerUser` function in the smart contract
  Future<void> registerUser(String username, String password) async {
    final function = _contract.function('registerUser');
    try {
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [username, password],
        ),
        chainId: 1337, // Ganache chain ID (default is 1337)
      );
      print("User registered successfully!");
    } catch (e) {
      print("Failed to register user: $e");
      rethrow;
    }
  }

  /// Authenticates a user by calling the `authenticate` function in the smart contract
  Future<bool> authenticate(String username, String password) async {
    final function = _contract.function('authenticate');
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [username, password],
      );
      return result.first as bool;
    } catch (e) {
      print("Authentication failed: $e");
      return false;
    }
  }
}
