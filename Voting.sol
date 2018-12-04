pragma solidity ^0.4.25;

contract SmartVoting {
    uint public totalAmountNeededForEvent = 0;
    uint public minAttendees = 1;
    uint public maxAttendees = 1;
    uint public maxPaymentPerAttendee = 0;
    uint64 public deadline;
    uint private repayment = 0;
    bool private eventAlreadyExisting = false;
    address owner = msg.sender;
    address[] private attendeeAccounts;
    mapping (address => Attendee) public attendees;
    mapping (address => bool) public admins;
    mapping (address => bool) public members;
    Attendee attendee;

    struct Attendee {
        uint balance;
        bool hasSignedUp;
    }

    // Modifiers
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

    // Events
    event CreateEvent(
        address indexed _from,
        uint _amount,
        uint _minAttendees,
        uint _maxAttendees,
        uint64 _deadline
    );

    event ConfirmEvent(
        address indexed _from
    );

    // Fallback function
    function() external payable {
        
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
    function createEvent(uint _amount, uint _minAttendees, uint _maxAttendees, uint64 _deadline) public onlyOwner {
        if(!eventAlreadyExisting) {
            attendeeAccounts.length = 0;
            totalAmountNeededForEvent = _amount;
            minAttendees = _minAttendees;
            maxAttendees = _maxAttendees;
            deadline = _deadline;
            maxPaymentPerAttendee = totalAmountNeededForEvent/minAttendees;
            eventAlreadyExisting = true;

            emit CreateEvent(msg.sender, _amount, _minAttendees, _maxAttendees, _deadline);
        }        
    }

    function confirmEvent() public payable onlyOwner {
        if(attendeeAccounts.length == maxAttendees || (block.number >= deadline && attendeeAccounts.length >= minAttendees)) {
            uint256 costPerAttendee = totalAmountNeededForEvent / attendeeAccounts.length;
            msg.sender.transfer(totalAmountNeededForEvent);
            
            // send difference back to all attendeeAccounts
            for(uint i = 0; i < attendeeAccounts.length; i++) {
                attendeeAccounts[i].transfer(attendees[attendeeAccounts[i]].balance - costPerAttendee);
                attendees[attendeeAccounts[i]].balance = 0;
            }
            eventAlreadyExisting = false;
            emit ConfirmEvent(msg.sender);
        }
    }

    function cancelEvent() public payable onlyOwner {
        // send funds back to all attendeeAccounts
        for(uint i = 0; i < attendeeAccounts.length; i++) {
            attendeeAccounts[i].transfer(attendees[attendeeAccounts[i]].balance);
            attendees[attendeeAccounts[i]].balance = 0;
        }
        eventAlreadyExisting = false;
    }

    // Function to sign up for the event
    function signUpForEvent() public payable onlyMembers {
        attendee = attendees[msg.sender];
        if(msg.value >= maxPaymentPerAttendee && block.number < deadline && !attendee.hasSignedUp) {
            attendee.hasSignedUp = true;
            attendee.balance = maxPaymentPerAttendee;
            attendeeAccounts.push(msg.sender);
            msg.sender.transfer(msg.value - maxPaymentPerAttendee);
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    // Function to send funds back if minAttendees was not reached
    function withdraw() public onlyMembers {
        if (block.number >= deadline && attendeeAccounts.length < minAttendees) {
            // send funds back to all attendeeAccounts
            for(uint i = 0; i < attendeeAccounts.length; i++) {
                attendee = attendees[attendeeAccounts[i]];
                attendeeAccounts[i].transfer(attendee.balance);
                attendee.balance = 0;
                attendee.hasSignedUp = false;
            }
            eventAlreadyExisting = false;
        }
    }

    function countAttendees() public view returns (uint) {
        return attendeeAccounts.length;
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }
    
    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }

    function isAttendee(address _address) public view returns (bool) {
        return members[_address];
    }

    function showMyBalance() public view returns (uint256) {
        return attendees[msg.sender].balance;
    }
}