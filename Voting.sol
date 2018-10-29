pragma solidity ^0.4.25;

contract SmartVoting {
    uint public totalAmountNeededForEvent = 0;
    uint public minAttendees = 1;
    uint public maxAttendees = 1;
    uint public numberOfAttendees = 0;
    uint64 public deadline;
    address owner = msg.sender;
    mapping (address => bool) public admins;
    mapping (address => bool) public members;
    mapping (address => bool) public attendees;
    
    modifier onlyOwner{ 
        require(
            msg.sender == owner,
            "Sender not authorized."
            ); 
        _;
    }

    modifier onlyAdmins{
        require(
            msg.sender == owner || admins[msg.sender] == true,
            "Sender not authorized."
            );
        _;
    }

    modifier onlyMembers {
        require(
            msg.sender == owner || admins[msg.sender] == true || members[msg.sender] == true,
            "Sender not authorized."
            );
        _;
    }

    // Fallback function
    function() public payable {
        uint _prePayment = totalAmountNeededForEvent/minAttendees;
        if(msg.value >= _prePayment && block.number < deadline && attendees[msg.sender] == false) {
            attendees[msg.sender] = true;
            numberOfAttendees += 1;
            // We keep the rest
        }
    }

    // Function to add a new member (only allowed by admins)
    function addMember(address _member) public onlyAdmins {
        members[_member] = true;
    }

    // Function to remove a member (only allowed by admins)
    function removeMember(address _member) public onlyAdmins {
        members[_member] = false;
    }

    // Function to add a new admin (only allowed by owner)
    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
    }

    // Function to remove an admin (only allowed by owner)
    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }

    // Function to set the amount that is required for the event
    function setEventDetails(uint _amount, uint _minAttendees, uint _maxAttendees, uint64 _deadline) public onlyAdmins {
        numberOfAttendees = 0;
        totalAmountNeededForEvent = _amount;
        minAttendees = _minAttendees;
        maxAttendees = _maxAttendees;
        deadline = _deadline;
    }

    // Function to sign up for the event
    function signUpForEvent(uint _amount) public payable onlyMembers {
        uint _prePayment = totalAmountNeededForEvent/minAttendees;
        if(_amount >= _prePayment && block.number < deadline && attendees[msg.sender] == false) {
            attendees[msg.sender] = true;
            numberOfAttendees += 1;
            // We keep the rest
        }
    }

    // Function to withdraw own amount
    function withdraw() public onlyMembers {
        if (block.number >= deadline && attendees[msg.sender] == true) {
            uint _prePayment = totalAmountNeededForEvent/minAttendees;
            uint _payback = _prePayment - totalAmountNeededForEvent/numberOfAttendees;
            attendees[msg.sender] = false;
            msg.sender.transfer(_payback);
        }
    }
}