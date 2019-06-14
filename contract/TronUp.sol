pragma solidity =0.4.25;

import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title ITRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address account, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed account, address indexed spender, uint256 value);
}

contract TRC20 is ITRC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;
    uint256 internal _totalMint;
    uint256 internal _totalBurnt;
    uint256 internal _totalBurntCount;
    
    event Minted(address indexed from, address indexed to, uint256 value);
    event Burnt(address indexed from, address indexed to, uint256 value);
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function totalMint() public view returns (uint256) {
        return _totalMint;
    }
    
    function totalBurnt() public view returns (uint256) {
        return _totalBurnt;
    }
    
    function totalBurntCount() public view returns (uint256) {
        return _totalBurntCount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address account, address spender) public view returns (uint256) {
        return _allowed[account][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalMint = _totalMint.add(value);
        _balances[address(this)] = _balances[address(this)].sub(value);
        _balances[account] = _balances[account].add(value);
        emit Minted(address(this), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _totalBurnt = _totalBurnt.add(value);
        _totalBurntCount = _totalBurntCount.add(1);
        
        _balances[account] = _balances[account].sub(value);
        emit Burnt(account, address(0), value);
    }

    function _approve(address account, address spender, uint256 value) internal {
        require(spender != address(0));
        require(account != address(0));

        _allowed[account][spender] = value;
        emit Approval(account, spender, value);
    }
    
}

contract TronUp is TRC20 {
    string public name = "TRON UP";
    string public symbol = "UP";
    uint8  public decimals = 6;
    
    uint256 internal _totalFrozen;
    uint256 private upPrice = 30000000;
    
    event Frozen(address account, uint256 value);
    event Unfrozen(address account, uint256 value, bool hourType);
    event UpPriceUpdate(uint256 upPrice, uint256 time);

    mapping (address => uint256) private _frozen;
    mapping (address => uint256) private _unfrozen_2;
    mapping (address => uint256) private _last_unfrozen_time_2;
    mapping (address => uint256) private _unfrozen_24;
    mapping (address => uint256) private _last_unfrozen_time_24;
    
    modifier onlyMinter() {
        require(approvedMinters[msg.sender] == true);
        _;
    }
    
    mapping(address => bool) private approvedMinters;
    
     /**
     * @dev constructor function.
     */
    constructor () public {
        _totalSupply = 1000000000000000; 
        _balances[address(this)] = _totalSupply;
    }
    
    function addMinter(address _minter) public onlyOwner {
        approvedMinters[_minter] = true;
    }
    
    function removeMinter(address _minter) public onlyOwner {
        approvedMinters[_minter] = false;
    }
    
    function updateUpPrice(uint256 _upPrice) public onlyMinter {
        upPrice = _upPrice;
        emit UpPriceUpdate(upPrice, now);
    }
    
    function mintScale() public view returns (uint256) {
        uint256 scale = uint256(3).mul(uint256(10 ** 10)).div(upPrice);
        return scale;
    }
    
    function getUpPrice() public view returns(uint256) {
        return upPrice;
    }
    
    /**
    * @dev Gets the 12 hours thaws token of the specified address.
    * @return An uint256 representing the amount thaws by the passed address.
    */
    function totalFrozen() public view returns (uint256) {
        return _totalFrozen;
    }
    
    /**
    * @dev Gets the 12 hours thaws token of the specified address.
    * @param account The address to query the frozen of.
    * @return An uint256 representing the amount thaws by the passed address.
    */
    function frozenOf(address account) public view returns (uint256) {
        return _frozen[account];
    }
    
    /**
    * @dev Gets the 12 hours thaws token of the specified address.
    * @param account The address to query the frozen of.
    * @return An uint256 representing the amount thaws by the passed address.
    */
    function unfrozen2HoursOf(address account) public view returns (uint256) {
        return _unfrozen_2[account];
    }

    /**
    * @dev Gets the 24 hours thaws token of the specified address.
    * @param account The address to query the frozen of.
    * @return An uint256 representing the amount thaws by the passed address.
    */
    function unfrozen24HoursOf(address account) public view returns (uint256) {
        return _unfrozen_24[account];
    }

    /**
    * @dev Gets the last 12 hours thaw time of the specified address.
    * @param account The address to query the last 12 hours thaw time of.
    * @return An uint256 representing the last 12 hours thaw time by the passed address.
    */
    function lastUnfrozenTime2Hours(address account) public view returns (uint256) {
        return _last_unfrozen_time_2[account];
    }

    /**
    * @dev Gets the last 24 hours thaw time of the specified address.
    * @param account The address to query the last 24 hours thaw time of.
    * @return An uint256 representing the last 24 hours thaw time by the passed address.
    */
    function lastUnfrozenTime24Hours(address account) public view returns (uint256) {
        return _last_unfrozen_time_24[account];
    }
    
    function transferByMinter(address from, address to, uint256 value) public onlyMinter returns (bool) {
        _transfer(from, to, value);
        return true;
    }
    
    /**
    * @dev Freeze token.
    * @param value The amount to be frozen.
    */
    function freeze(uint256 value) public returns (bool) {
        require( value >= 10000000, "Don't equal 0x0000000000000000000000000000000000000000");
        require(_balances[msg.sender] >= value, "balance of msg.sender more than value.");
        
        _totalFrozen = _totalFrozen.add(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _frozen[msg.sender] = _frozen[msg.sender].add(value);
        
        emit Frozen(msg.sender, value);
        return true;
    }

    /**
    * @dev Thaw 12 hours token.
    */
    function unfrozen2Hours() public returns (bool) {
        require( _frozen[msg.sender] >= 0, "Frozen UPs must be more than 0.");

        _last_unfrozen_time_2[msg.sender] = now + 2 hours;

        uint256 value = _frozen[msg.sender];
        _frozen[msg.sender] = 0;

        _totalFrozen = _totalFrozen.sub(value);
        //销毁30%
        uint256 _burned = value.mul(30).div(100);
        _burn(msg.sender, _burned);

        _unfrozen_2[msg.sender] = _unfrozen_2[msg.sender].add(value.sub(_burned));
        emit Unfrozen(msg.sender, value, true);

        return true;
    }

    /**
    * @dev Thaw 24 hours token.
    */
    function unfrozen24Hours() public returns (bool) {
        require( _frozen[msg.sender] >= 0, "Frozen UPs must be more than 0.");

        _last_unfrozen_time_24[msg.sender] = now + 24 hours;
        
        uint256 value = _frozen[msg.sender];
        _frozen[msg.sender] = 0;
        _totalFrozen = _totalFrozen.sub(value);
        _unfrozen_24[msg.sender] = _unfrozen_24[msg.sender].add(value);

        emit Unfrozen(msg.sender, value, false);
        return true;
    }

    /**
    * @dev Withdraw all 12 hours thawed tokens. Last thaw time must be out of 12 hours.
    */
    function withdraw2Hours() public returns (bool) {
        require( _unfrozen_2[msg.sender] > 0, "Unfrozen of Ups should not be empty." );
        require( now > _last_unfrozen_time_2[msg.sender], "Withdraw 12 hours after Unfrozen.");

        uint256 value = _unfrozen_2[msg.sender];
        _unfrozen_2[msg.sender] = 0;
        _last_unfrozen_time_2[msg.sender] = 0;
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(this), msg.sender, value);
        
        return true;
    }

    /**
    * @dev Withdraw all 24 hours thawed tokens. Last thaw time must be out of 24 hours.
    */
    function withdraw24Hours() public returns (bool) {
        require( _unfrozen_24[msg.sender] > 0, "Unfrozen of Ups should not be empty." );
        require( now > _last_unfrozen_time_24[msg.sender], "Withdraw 24 hours after Unfrozen.");

        uint256 value = _unfrozen_24[msg.sender];
        _unfrozen_24[msg.sender] = 0;
        _last_unfrozen_time_24[msg.sender] = 0;
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(this), msg.sender, value);
        
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    
    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param from The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function burnFrom(address from, uint256 value) internal {
        _burn(from, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    }
    
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintByMinter(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Burn by minter.
     * @param from The address that will be burned the tokens.
     * @param value The amount of tokens to burn.
     * @return A boolean that indicates if the operation was successful.
     */
    function burnByMinter(address from, uint256 value) public onlyMinter returns (bool) {
        _burn(from, value);
        return true;
    }
    
    function dividBurntByMinter(address account, uint256 value) public onlyMinter returns (bool) {
        require(account != address(0));
        require(value <= _frozen[account], "value less than frozen.");
        _totalSupply = _totalSupply.sub(value);
        _totalFrozen = _totalFrozen.sub(value);
        _totalBurnt = _totalBurnt.add(value);
        _totalBurntCount = _totalBurntCount.add(1);
        
        _frozen[account] = _frozen[account].sub(value);
        
        emit Burnt(account, address(0), value);
    }

}
