// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthcareRecord {
    struct Patient {
        string name;
        string surname;
        string email;
        string gender;
        string doctorName;
        uint doctorId;
        string results;
        string predictions;
        string cid; // Content Identifier for IPFS/File Storage
    }

    mapping(address => Patient) private patients;
    address[] private patientAddresses;

    event PatientAdded(
        address indexed patientAddress,
        string name,
        string surname
    );

    function addPatient(
        address patientAddress,
        string memory name,
        string memory surname,
        string memory email,
        string memory gender,
        string memory doctorName,
        uint doctorId,
        string memory results,
        string memory predictions,
        string memory cid
    ) public {
        require(bytes(name).length > 0, "Name is required");
        require(bytes(email).length > 0, "Email is required");

        Patient memory newPatient = Patient(
            name,
            surname,
            email,
            gender,
            doctorName,
            doctorId,
            results,
            predictions,
            cid
        );

        patients[patientAddress] = newPatient;
        patientAddresses.push(patientAddress);

        emit PatientAdded(patientAddress, name, surname);
    }

    function getPatient(address patientAddress)
        public
        view
        returns (Patient memory)
    {
        return patients[patientAddress];
    }

    function getAllPatients() public view returns (address[] memory) {
        return patientAddresses;
    }
}
