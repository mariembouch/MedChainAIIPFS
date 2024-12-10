import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart'; // For WebSocket connection

class ContractLinking extends ChangeNotifier {
  bool isLoading = true;
  late Web3Client ethClient;
  late DeployedContract contract;
  late String contractAddress;
  late String _abiCode;

  final String rpcUrl = "http://127.0.0.1:7545"; // Ganache RPC URL
  final String wsUrl = "ws://127.0.0.1:7545"; // Ganache WebSocket URL
  final String privateKey =
      "0x70807b05e02e474acacab6c24e7a1db686b1ad6e0127ca2fbe6b58a09a09af71"; // Replace with your Ganache private key

  Credentials? credentials;

  ContractLinking() {
    initialize();
  }

  Future<void> initialize() async {
    await initialSetup();
    isLoading = false;
    notifyListeners();
  }

  // Function to establish Web3Client connection
  Future<void> initialSetup() async {
    // Web3Client setup using WebSocket for real-time events
    ethClient = Web3Client(rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(wsUrl).cast<String>();
    });

    // Load the contract ABI and setup the deployed contract
    await getAbi();
    await getCredentials();
  }

  // Function to load the ABI from the asset and initialize the contract
  Future<void> getAbi() async {
    String abiString =
        await rootBundle.loadString("src/artifacts/HealthcareRecord.json");
    var jsonAbi = jsonDecode(abiString);

    // Extract the ABI from the loaded JSON
    _abiCode = jsonEncode(jsonAbi["abi"]);
    print("Contract ABI: $_abiCode");

    // Set the contract address (replace with actual address from deployment)
    contractAddress = jsonAbi["networks"]["1337"]["address"];
    print("Contract Address: $contractAddress");

    // Initialize the deployed contract
    contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HealthcareRecord"),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  // Function to get the Ethereum credentials from the private key
  Future<void> getCredentials() async {
    credentials = EthPrivateKey.fromHex(privateKey);
  }

  // Function to add a new patient to the blockchain
  Future<void> addPatient(
    String address,
    String name,
    String surname,
    String email,
    String gender,
    String doctorName,
    int doctorId,
    String results,
    String predictions,
    String cid,
  ) async {
    final function = contract.function("addPatient");

    await ethClient.sendTransaction(
      credentials!,
      Transaction.callContract(
        contract: contract,
        function: function,
        parameters: [
          EthereumAddress.fromHex(address),
          name,
          surname,
          email,
          gender,
          doctorName,
          BigInt.from(doctorId),
          results,
          predictions,
          cid,
        ],
      ),
      chainId: 1337, // Ganache local chain
    );

    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPatient(String address) async {
    try {
      final function = contract.function("getPatient");
      final result = await ethClient.call(
        contract: contract,
        function: function,
        params: [EthereumAddress.fromHex(address)],
      );

      // Parse and display the result
      if (result.isNotEmpty) {
        print("Patient Data:");
        print("Name: ${result[0]}");
        print("Surname: ${result[1]}");
        print("Email: ${result[2]}");
        print("Gender: ${result[3]}");
        print("Doctor Name: ${result[4]}");
        print("Doctor ID: ${result[5]}");
        print("Results: ${result[6]}");
        print("Predictions: ${result[7]}");
        print("CID: ${result[8]}");
      } else {
        print("No data found for this address.");
      }
    } catch (e) {
      print("Error while fetching patient data: $e");
    }
  }
}
