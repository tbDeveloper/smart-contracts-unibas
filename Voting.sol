pragma solidity ^0.5.0;

contract SmartVoting {
    uint public totalAmountNeededForEvent = 0 ether;
    uint public minAttendees = 1;
    uint public maxAttendees = 1;
    uint public numberOfAttendees = 0;
    uint public pot = 0 ether;
    uint public maxPaymentPerAttendee = 0 ether;
    uint private repayment = 0;
    bool public eventAlreadyExisting = false;
    uint64 public deadline;
    address owner = msg.sender;
    address[] public attendees;
    mapping (address => bool) public attendeesMapping;
    mapping (address => bool) public admins;
    mapping (address => bool) public members;
    mapping (address => uint) public accountBalance;


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
        // Test
    }

    // Function to add a new member (only allowed by admins)
    function addMember(address _member) public onlyAdmins {
        members[_member] = true;
    }

    // Function to remove a member (only allowed by admins)
    function removeMember(address _member) public onlyAdmins {
        members[_member] = false;

        if(!admins[_member] && _member != owner) {
            // fix this
            _member.transfer(accountBalance[_member]);
        }
    }

    function removeAttendee(address _attendee) public onlyOwner { 
        // todo: fix this
        _attendee.transfer(accountBalance[_attendee]);
        // todo fix (Array)
        attendees[_attendee] = false;
    }

    // Function to add a new admin (only allowed by owner)
    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
    }

    // Function to remove an admin (only allowed by owner)
    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;

        if(!members[_admin] && _admin != owner) {
            _admin.transfer(accountBalance[_admin]);
        }
    }

    // Function to set the amount that is required for the event
    function createEvent(uint _amount, uint _minAttendees, uint _maxAttendees, uint _deadline) public onlyOwner {
        if(!eventAlreadyExisting) {
            numberOfAttendees = 0;
            totalAmountNeededForEvent = _amount;
            minAttendees = _minAttendees;
            maxAttendees = _maxAttendees;
            deadline = _deadline;
            maxPaymentPerAttendee = totalAmountNeededForEvent/minAttendees;
            eventAlreadyExisting = true;
        }        
    }

    function confirmEvent() public onlyOwner {
        if(numberOfAttendees = maxAttendees || (block.number >= deadline && numberOfAttendees >= minAttendees)) {
            repayment = (this.balance - totalAmountNeededForEvent) / numberOfAttendees;
            msg.sender.transfer(totalAmountNeededForEvent);
            
            // send difference back to all attendees
            for(uint i = 0; i < attendees.length; i++) {
                attendees[i].transfer(repayment);
            }

            eventAlreadyExisting = false;
        }
    }

    function cancelEvent() public onlyOwner {
        repayment = this.balance / numberOfAttendees;
        
        // send funds back to all attendees
        for(uint i = 0; i < attendees.length; i++) {
            attendees[i].transfer(repayment);
        }

        eventAlreadyExisting = false;
    }

    // Function to sign up for the event
    function signUpForEvent() public payable onlyMembers {
        if(msg.value >= maxPaymentPerAttendee && block.number < deadline && !attendees[msg.sender]) {
            attendees[numberOfAttendees] = msg.sender;
            attendeesMapping[msg.sender] = true;
            numberOfAttendees += 1;
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