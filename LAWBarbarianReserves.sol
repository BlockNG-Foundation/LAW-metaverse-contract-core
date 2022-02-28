pragma solidity 0.5.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract LAWBarbarianReserves {
    //helpers
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;


    address public gov;

    address public pendingGov;

    address public barbarianAddress;

    address public lawAddress;

    uint256 public constant START = 1646092800;// 2022-03-01 0:00:00 UTC

    uint256 public constant EACHPERIOD = 72246e18;

    uint256 public alreadySent;


    /*** Gov Events ***/

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(address oldGov, address newGov);


    /**
     * @notice Event emitted when barbarianAddress received Law
     */
    event Flag(uint256 amount);


    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    constructor(
        address lawAddress_, address barbarianAddress_
    )
    public
    {
        barbarianAddress = barbarianAddress_;
        lawAddress = lawAddress_;
        gov = msg.sender;
    }

    function sendLawToBarbarian()
    external
    {
        uint256 timestampBasedOn = block.timestamp;
        require(msg.sender == gov || msg.sender == barbarianAddress,"only barbarianAddress");
        require(block.timestamp >= START ,"not start yet");

        uint month;
        (,month,) = _daysToDate(timestampBasedOn / SECONDS_PER_DAY);
        uint multiplier = month < 3 ? month + 10 : month -2;

        require(multiplier <= 12 ,"overflow");

        uint needToSend = multiplier * EACHPERIOD - alreadySent;

        alreadySent = alreadySent + needToSend;

        if(needToSend > 0){
            IERC20(lawAddress).transfer(barbarianAddress,needToSend);
            emit Flag(needToSend);
        }
    }

    /**
     * @notice only emergency
     */
    function _sendLaw(address target,uint256 bal)
    external
    onlyGov
    {
        IERC20(lawAddress).transfer(target,bal);
    }



    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the rebaser contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_)
    external
    onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /**
     * @notice lets msg.sender accept governance
     */
    function _acceptGov()
    external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }



    function laws()
    public
    view
    returns (uint256)
    {
        return IERC20(lawAddress).balanceOf(address(this));
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}
