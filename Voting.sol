pragma solidity ^0.5.0;

contract SmartVoting {
    uint public totalAmountNeededForEvent = 0;
    uint public minAttendees = 1;
    uint public maxAttendees = 1;
    uint public maxPaymentPerAttendee = 0;
    uint64 public deadline;
    uint private repayment = 0;
    bool public eventAlreadyExisting = false;
    address owner = msg.sender;
    uint public numberOfAttendees;
    mapping (address => uint) public balance;
    mapping (uint => address payable) public attendees;
    mapping (address => bool) public admins;
    mapping (address => bool) public members;

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

    // Function to set the event details
    function createEvent(uint _amount, uint _minAttendees, uint _maxAttendees, uint64 _deadline) public onlyOwner {
        if(!eventAlreadyExisting) {
            totalAmountNeededForEvent = _amount;
            minAttendees = _minAttendees;
            maxAttendees = _maxAttendees;
            deadline = _deadline;
            maxPaymentPerAttendee = totalAmountNeededForEvent/minAttendees;
            eventAlreadyExisting = true;

            emit CreateEvent(msg.sender, _amount, _minAttendees, _maxAttendees, _deadline);
        }        
    }

    // Function to sign up for the event
    function signUpForEvent() public payable onlyMembers {
        if(msg.value >= maxPaymentPerAttendee && block.number < deadline && balance[msg.sender] == 0 && numberOfAttendees < maxAttendees) {
            attendees[numberOfAttendees] = msg.sender;
            numberOfAttendees += 1;
            balance[msg.sender] = maxPaymentPerAttendee;
            msg.sender.transfer(msg.value - maxPaymentPerAttendee);
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    function confirmEvent() public payable onlyOwner {
        if(numberOfAttendees == maxAttendees || (block.number >= deadline && numberOfAttendees >= minAttendees)) {
            uint256 costPerAttendee = totalAmountNeededForEvent / numberOfAttendees;
            msg.sender.transfer(totalAmountNeededForEvent);
            
            // send difference back to all attendees
            payBack(costPerAttendee);
            resetEvent();
        }
    }

    function cancelEvent() public payable onlyOwner {
        // send funds back to all attendees
        payBack(0);
        resetEvent();
    }

    // Function to send funds back if minAttendees was not reached
    function withdraw() public payable onlyMembers {
        if (block.number >= deadline && numberOfAttendees < minAttendees) {
            // send funds back to all attendees
            payBack(0);
            resetEvent();
        }
    }

    function resetEvent() private {
        totalAmountNeededForEvent = 0;
        minAttendees = 1;
        maxAttendees = 1;
        maxPaymentPerAttendee = 0;
        deadline = 0;
        eventAlreadyExisting = false;
        numberOfAttendees = 0;
    }

    function payBack(uint _residual) private {
        for(uint i = 0; i < numberOfAttendees; i++) {
            attendees[i].transfer(balance[attendees[i]] - _residual);
            balance[attendees[i]] = 0;
            attendees[i] = 0x0000000000000000000000000000000000000000;
        }
    }
}