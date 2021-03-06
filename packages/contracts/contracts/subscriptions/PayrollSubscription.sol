pragma solidity 0.4.24;

import "../interfaces/BillableInterface.sol";
import "../interfaces/ApprovedRegistryInterface.sol";

import "../Authorizable.sol";

/** @title Contains all the data required for payroll subscriptions. */
/** @author Kerman Kohli - <kerman@8xprotocol.com> */

contract PayrollSubscription is Authorizable, BillableInterface {

    struct Payment {
        uint256 amount;                     // Editable
        address destination;                // Editable
        uint256 lastPaymentDate;            // Editable (authorised)
        uint256 terminationDate;            // Can only be set once
        bytes32 scheduleIdentifier;         // Can only be set on creation
    }
    
    struct Schedule {
        uint256 interval;                   // Not editable
        uint256 fee;                        // Editable, expressed as a divisor to 2 decimals. 10000 = 0.01%.
        address tokenAddress;               // Not editable
        uint256 startDate;                  // Editable
        uint256 terminationDate;            // Can only be set once
        bool oneOff;                        // Can only be set on creation
        address owner;                      // Editable
        string data;                        // Editable
    }

    ApprovedRegistryInterface public approvedRegistry;

    mapping (bytes32 => Payment) public payments;
    mapping (bytes32 => Schedule) public schedules;

    uint256 public gasPrice = 2*10**9;
    uint256 public gasCost = 200000;

    event CreatedSchedule (
        bytes32 indexed scheduleIdentifier,
        address indexed owner,
        uint256 indexed startDate,
        uint256 interval,
        bool oneOff,
        uint256 fee
    );

    event UpdatedSchedule (
        bytes32 indexed scheduleIdentifier,
        address indexed owner,
        uint256 indexed startDate,
        uint256 interval,
        address tokenAddress,
        uint256 fee
    );

    event TerminatedSchedule (
        bytes32 indexed scheduleIdentifier,
        address indexed owner,
        uint256 indexed terminationDate
    );

    event CreatedPayment (
        bytes32 indexed paymentIdentifier,
        bytes32 indexed scheduleIdentifier,
        uint256 indexed amount
    );

    event UpdatedPayment (
        bytes32 indexed paymentIdentifier,
        uint256 indexed amount,
        address indexed destination,
        bytes32 scheduleIdentifier
    );

    event LastUpdatedPaymentDate(
        bytes32 indexed paymentIdentifier,
        bytes32 indexed scheduleIdentifier,
        uint256 indexed lastPaymentDate,
        bool isLastPayment
    );

    event TerminatedPayment (
        bytes32 indexed paymentIdentifier,
        bytes32 indexed scheduleIdentifier,
        uint256 indexed terminationDate
    );
 
    /**
      * BILLABLE INTERFACE FUNCTIONS
    */
    function getPaymentStatus(bytes32 _paymentIdentifier)
        public
        view
        returns (uint256 status)
    {
        Payment memory payment = payments[_paymentIdentifier];

        if (
            schedules[payment.scheduleIdentifier].terminationDate > 0 || 
            payment.terminationDate > 0 ||
            (schedules[payment.scheduleIdentifier].oneOff == true && payment.lastPaymentDate > 0)
        ) {
            // Terminated payment
            return 3;
        }

        if (payment.lastPaymentDate > 0) {
            // Active payment
            return 2;
        }

        if (currentTimestamp() >= schedules[payment.scheduleIdentifier].startDate) {
            // Ready to be executed
            return 1;
        }

        // Not ready to be started
        return 0;
    }

    function getPaymentTokenAddress(bytes32 _paymentIdentifier)
        public
        view
        returns (address subscriptionTokenAddress)
    {
        Payment memory payment = payments[_paymentIdentifier];
        return schedules[payment.scheduleIdentifier].tokenAddress;
    }

    function getPaymentFromToAddresses(bytes32 _paymentIdentifier)
        public
        view
        returns (address from, address to)
    {
        Payment memory payment = payments[_paymentIdentifier];
        return (schedules[payment.scheduleIdentifier].owner, payment.destination);
    }

    function getPaymentInterval(bytes32 _paymentIdentifier)
        public
        view
        returns (uint256 interval)
    {
        Payment memory payment = payments[_paymentIdentifier];
        return schedules[payment.scheduleIdentifier].interval;
    }

    function getAmountDueFromPayment(bytes32 _paymentIdentifier)
        public
        view
        returns (uint256 amount)
    {
        return payments[_paymentIdentifier].amount;
    }

    function getPaymentFee(bytes32 _paymentIdentifier)
        public
        view
        returns (uint256 fee)
    {
        Payment memory payment = payments[_paymentIdentifier];
        return (payment.amount / schedules[payment.scheduleIdentifier].fee);
    }

    function getLastPaymentDate(bytes32 _paymentIdentifier)
        public
        view
        returns (uint256 date)
    {
        return payments[_paymentIdentifier].lastPaymentDate;
    }

    function getGasForExecution(bytes32 _paymentIdentifier, uint256 _type)
        public
        view
        returns (uint256 returnedGasCost, uint256 returnedGasPrice)
    {
        return (gasCost, gasPrice);
    }

    function setLastestPaymentDate(uint256 _date, bytes32 _paymentIdentifier)
        public
        onlyAuthorized
        returns (bool success, bool isFinalPayment)
    {

        Payment storage payment = payments[_paymentIdentifier];

        require(payment.lastPaymentDate <= _date, "Latest payment date is less than older date");

        payment.lastPaymentDate = _date;

        emit LastUpdatedPaymentDate(
            _paymentIdentifier,
            payment.scheduleIdentifier,
            _date,
            schedules[payment.scheduleIdentifier].oneOff
        );

        return (true, schedules[payment.scheduleIdentifier].oneOff);

    }

    function cancelPayment(bytes32 _paymentIdentifier)
        public
    {

        Payment storage payment = payments[_paymentIdentifier];

        require((msg.sender == payment.destination) || authorized[msg.sender] == true || msg.sender == schedules[payment.scheduleIdentifier].owner, "Must be the owner or an authorised contract");

        // If it hasn't been terminated, do it. Doesn't throw in case the executor calls it without knowing the status.
        if (payment.terminationDate == 0) {
            uint256 cancellationTimestamp = currentTimestamp();
            payment.terminationDate = cancellationTimestamp;

            emit TerminatedPayment (
                _paymentIdentifier,
                payment.scheduleIdentifier,
                payment.terminationDate
            );
        }

    }

    /**
      * PUBLIC FUNCTIONS
    */
    constructor(address _approvedRegistryAddress) public {
        approvedRegistry = ApprovedRegistryInterface(_approvedRegistryAddress);
    }

    /** @dev Update the gas price for processing a subscription.
      * @param _gasPrice price to set.
    */
    function setGasPrice(uint256 _gasPrice) public onlyOwner {
        gasPrice = _gasPrice;
    }

    /** @dev Update the gas cost for processing a subscription.
      * @param _gasCost cost to set.
    */
    function setGasCost(uint256 _gasCost) public onlyOwner {
        gasCost = _gasCost;
    }

    function createScheduleWithPayments(
        bytes32[] _ids,
        uint256[] _amounts,
        address[] _destinations,
        address _tokenAddress,
        uint256 _startDate,
        uint256 _interval,
        uint256 _fee,
        bool _oneOff,
        string _data
    ) 
        public
    {

        require(_startDate > 0, "You need to set a starting date");
        require(_fee > 0, "Cannot create payment with no fee");
        require((_oneOff == false && _interval > 0) || (_oneOff == true), "If the payment is not one off, it requires an interval");

        // @TODO: Add tests for this
        require(approvedRegistry.isTokenAuthorised(_tokenAddress), "It must be an authorised token");

        // @TODO: Add tests for this
        require(_ids.length > 0, "You need to pass in at least one identifier");
    
        Schedule memory newSchedule = Schedule(
            _interval,
            _fee,
            _tokenAddress,
            _startDate,
            0,
            _oneOff,
            msg.sender,
            _data
        );
        
        bytes32 scheduleHash = keccak256(msg.sender, _tokenAddress, _oneOff, currentTimestamp());
        require(schedules[scheduleHash].owner == 0, "There must not already be a schedule with the same hash");

        schedules[scheduleHash] = newSchedule;

        emit CreatedSchedule(
            scheduleHash,
            msg.sender,
            _startDate,
            _interval,
            _oneOff,
            _fee
        );

        _createPayments(_ids, _amounts, _destinations, scheduleHash);
        
    }

    function _createPayments(
        bytes32[] _ids,
        uint256[] _amounts,
        address[] _destinations,
        bytes32 _scheduleHash
    )   
        private
    {
        for (uint256 i = 0; i < _ids.length; i++)  {
            _createPayment(_ids[i], _amounts[i], _destinations[i], _scheduleHash);
        }
    }

    function _createPayment(
        bytes32 _id,
        uint256 _amount,
        address _destination,
        bytes32 _scheduleHash
    )
        private
    {
        Payment memory newPayment = Payment(
            _amount,
            _destination,
            0,
            0,
            _scheduleHash
        );
        
        require(payments[_id].scheduleIdentifier == 0, "There must not be a payment with an existing schedule identifier");
        require(schedules[_scheduleHash].owner == msg.sender, "You cannot create a payment under someone else's schedule");
        payments[_id] = newPayment;

        emit CreatedPayment (
            _id,
            _scheduleHash,
            _amount
        );
    }

    function updateScheduleOwner(
        bytes32 _scheduleIdentifier,
        address _owner
    ) 
        public
    {

        Schedule storage schedule = schedules[_scheduleIdentifier];

        require(schedule.owner == msg.sender, "Must be the original owner to set a new owner");

        schedule.owner = _owner;
        
        emit UpdatedSchedule(
            _scheduleIdentifier,
            _owner,
            schedule.startDate,
            schedule.interval,
            schedule.tokenAddress,
            schedule.fee
        );

    }

    function updateStartDate(
        bytes32 _scheduleIdentifier,
        uint256 _startDate
    ) 
        public
    {
        
        Schedule storage schedule = schedules[_scheduleIdentifier];

        require(schedule.owner == msg.sender, "Must be the original owner to set a new owner");
        require(_startDate > currentTimestamp(), "Must be a date in the future");

        schedule.startDate = _startDate;

        emit UpdatedSchedule(
            _scheduleIdentifier,
            schedule.owner,
            _startDate,
            schedule.interval,
            schedule.tokenAddress,
            schedule.fee
        );
    }

    function updateScheduleData(
        bytes32 _scheduleIdentifier,
        string _data
    )
        public
    {

        Schedule storage schedule = schedules[_scheduleIdentifier];
        require(schedule.owner == msg.sender, "Must be the original owner to set the data");

        schedule.data = _data;

        emit UpdatedSchedule(
            _scheduleIdentifier,
            schedule.owner,
            schedule.startDate,
            schedule.interval,
            schedule.tokenAddress,
            schedule.fee
        );

    }

    /** @dev Terminate a payment schedule */
    function terminateSchedule(
        bytes32 _scheduleIdentifier,
        uint256 _terminationDate
    )
        public
    {

        Schedule storage schedule = schedules[_scheduleIdentifier];

        require(schedule.owner == msg.sender, "Must be the original owner to set a new owner");
        require(_terminationDate > currentTimestamp(), "The termination date must be greater than the timestamp");

        schedule.terminationDate = _terminationDate;

        emit TerminatedSchedule (
            _scheduleIdentifier,
            schedule.owner,
            _terminationDate
        );

    }


    /** @dev Update multiple payments at once
      * @param _ids all the identifiers you wish to update.
      * @param _amounts all the corresponding amount dates.
      * @param _destinations all the corresponding destination addresses to pay out.
    */
    function updatePayments(
        bytes32[] _ids,
        uint256[] _amounts,
        address[] _destinations,
        bytes32 _scheduleIdentifier
    ) 
        public
    {
        for (uint256 i = 0; i < _ids.length; i++)  {
            bytes32 id = _ids[i];
            if (payments[id].scheduleIdentifier != 0) {
                _updatePayment(id, _amounts[i], _destinations[i], _scheduleIdentifier);
            } else {
                _createPayment(id, _amounts[i], _destinations[i], _scheduleIdentifier);
            }
        }
    }   

    function _updatePayment(
        bytes32 _id,
        uint256 _amount,
        address _destination,
        bytes32 _scheduleIdentifier
    )
        private
    {
        Payment storage payment = payments[_id];
        payment.amount = _amount;
        payment.destination = _destination;

        require(schedules[_scheduleIdentifier].owner == msg.sender, "You cannot update someone else's schedule");

        emit UpdatedPayment(
            _id,
            _amount,
            _destination,
            _scheduleIdentifier
        );
    }

    /** @dev Terminate multiple payments at once
      * @param _ids all the identifiers you wish to terminate.
      * @param _terminationDates all the corresponding termination dates.
    */
    function terminatePayments(
        bytes32[] _ids,
        uint256[] _terminationDates
    )
        public
    {
        
        for (uint256 i = 0; i < _ids.length; i++)  {

            require(_terminationDates[i] > currentTimestamp(), "The termination date must be greater than the current timestamp");
            
            bytes32 id = _ids[i];
            Payment storage payment = payments[id];
            payment.terminationDate = _terminationDates[i];

            require(schedules[payment.scheduleIdentifier].owner == msg.sender, "You cannot update someone else's payment");

            emit TerminatedPayment (
                id,
                payment.scheduleIdentifier,
                _terminationDates[i]
            );

        }

    }

    /**
      * INTERNAL FUNCTIONS
    */
    /** @dev Current timestamp returned via a function in order for mocks in tests
    */
    function currentTimestamp()
        internal
        view
        returns (uint256 timetstamp)
    {
        // solhint-disable-next-line
        return block.timestamp;
    }
}