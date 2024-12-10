// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Login {
    struct User {
        string username;
        string password; // Do not store plain passwords in production
    }

    mapping(string => User) private users;

    function registerUser(string memory _username, string memory _password) public {
        require(bytes(users[_username].username).length == 0, "User already exists");
        users[_username] = User(_username, _password);
    }

    function authenticate(string memory _username, string memory _password) public view returns (bool) {
        return keccak256(bytes(users[_username].password)) == keccak256(bytes(_password));
    }
}