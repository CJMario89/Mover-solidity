// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() { // set contract related
        _checkOwner();
        _;
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract Manageable is Context, Ownable{

    address[] internal Managers;
    
    modifier onlyManager() { // set attribute related
        _checkManager();
        _;
    }

    function _checkManager () public view{
        require(isManager(_msgSender()), "Ownable: caller is not the manager");
    }

    function isManager (address addr) internal view returns(bool){
        for(uint256 i = 0; i < Managers.length; i++){
            if(Managers[i] == addr){
                return true;
            }
        }
        return false;
    }

    function setManager (address addr) public onlyOwner{
        require(!isManager(addr), "This address has already been manager");
        Managers.push(addr);
    }
}


contract MoverCore is Context, Ownable, Pausable, ERC721, Manageable, ReentrancyGuard{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 constant public MoverPrice = 1 ether; 
    uint256 constant public MoverClonePrice = 0.3 ether;

    uint256 constant public MAX_LEVEL = 30;
    // uint256 constant public MAX_POWER = 30;
    // uint256 constant public MAX_METABOLISM = 30;
    // uint256 constant public MAX_COORDINATION = 30;
    // uint256 constant public MAX_VITALITY = 30;
    // uint256 constant public MAX_RARITY = 30;

    uint256 constant public GRAY = 0;
    uint256 constant public GREEN = 1;
    uint256 constant public BLUE = 2;
    uint256 constant public PURPLE = 3;
    uint256 constant public ORANGE = 4;

    Counters.Counter internal _tokenIdCounter;
    Counters.Counter internal _teamMintAmount;
    Counters.Counter internal _marketingMintAmount;

    uint256 internal random_nonce = 0;

    constructor() ERC721("Mover", "Mover") {
        _tokenIdCounter.increment();
    }

    struct Mover{
        uint256 level;
        uint256 power;
        uint256 metabolism;
        uint256 coordination;
        uint256 vitality;
        uint256 rarity;// 0 gray, 1 green, 2 blue, 3 purple, 4 orange
        uint256 lucky;
        uint256 clone;// 5 stage clone
        bool isClone;
    }

    mapping (uint256 => Mover) internal mover; //token_id to Mover 

    // function getMoverInfo(uint256 token_id) public view returns (uint256[5] memory){
    //     require(_exists(token_id), "The token doesn't exist");
    //     uint256[5] memory data = [mover[token_id].level, mover[token_id].power, mover[token_id].metabolism, mover[token_id].coordination,  mover[token_id].vitality];
    //     return data;
    // }
    // function getMoverInfo1(uint256 token_id) public view returns (uint256[3] memory, bool){
    //     require(_exists(token_id), "The token doesn't exist");
    //     uint256[3] memory data = [mover[token_id].rarity, mover[token_id].lucky, mover[token_id].clone];
    //     return ( data, mover[token_id].isClone);
    // }

    function getMoverInfo(uint256 token_id) public view returns (uint256[8] memory, bool){
        require(_exists(token_id), "The token doesn't exist");
        uint256[8] memory data;
        data[0] = mover[token_id].level;
        data[1] = mover[token_id].power;
        data[2] = mover[token_id].metabolism;
        data[3] = mover[token_id].coordination;
        data[4] = mover[token_id].vitality;
        data[5] = mover[token_id].rarity;
        data[6] = mover[token_id].lucky;
        data[7] = mover[token_id].clone;
        bool isClone = mover[token_id].isClone;
        return (data, isClone);
    }

    function increase_capability (uint256 token_id, uint256 power, uint256 metabolism, uint256 coordination, uint256 vitality) public onlyManager{
        mover[token_id].power = SafeMath.add(mover[token_id].power, power);
        mover[token_id].metabolism = SafeMath.add(mover[token_id].metabolism, metabolism);
        mover[token_id].coordination = SafeMath.add(mover[token_id].coordination, coordination);
        mover[token_id].vitality = SafeMath.add(mover[token_id].vitality, vitality);
    }

    function upgrade (uint256 token_id) public onlyManager(){
        require(mover[token_id].level < MAX_LEVEL, "You have already been max level");
        mover[token_id].level = SafeMath.add(mover[token_id].level, 1);

        if(mover[token_id].isClone == false){
            if(mover[token_id].level == 5){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
            if(mover[token_id].level == 10){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
            if(mover[token_id].level == 15){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
            if(mover[token_id].level == 20){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
            if(mover[token_id].level == 25){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
            if(mover[token_id].level == 30){
                mover[token_id].clone = SafeMath.add(mover[token_id].clone, 1);
            }
        }
    }


    
    function random100() view internal returns(uint256){
        random_nonce.add(1);
        //0-99
        return SafeMath.mod(uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), random_nonce))), 100);
    }


}

//get ok
//set tx.origin?? (onlyManager)


contract Origin is MoverCore{
    using Counters for Counters.Counter;

    function public_mint () public payable nonReentrant whenNotPaused{
        require(_tokenIdCounter.current() <= 10000, "Exceed team mint limit");

        _safeMint(_msgSender(), _tokenIdCounter.current());
        pay();

        initial_Mover(_tokenIdCounter.current());
        _tokenIdCounter.increment();

    }                               

    function team_mint () public nonReentrant whenNotPaused onlyOwner{
        require(_teamMintAmount.current() <= 20, "Exceed team mint limit");
        require(_tokenIdCounter.current() <= 10000, "Exceed team mint limit");

        _safeMint(_msgSender(), _tokenIdCounter.current());
        initial_Mover(_tokenIdCounter.current());

        _tokenIdCounter.increment();
        _teamMintAmount.increment();
    }

    function marketing_mint () public nonReentrant whenNotPaused onlyOwner{
        require(_marketingMintAmount.current() <= 100, "Exceed team mint limit");
        require(_tokenIdCounter.current() <= 10000, "Exceed team mint limit");

        _safeMint(_msgSender(), _tokenIdCounter.current());
        initial_Mover(_tokenIdCounter.current());

        _tokenIdCounter.increment();
        _marketingMintAmount.increment();

    }


    function initial_Mover(uint256 token_id) internal {
        mover[token_id].level = 1;
        mover[token_id].power = 100;
        mover[token_id].metabolism = 100;
        mover[token_id].coordination = 100;
        mover[token_id].vitality = 50;
        mover[token_id].rarity = rarity_determine();
        mover[token_id].isClone = false;
    }


    function rarity_determine() view internal returns(uint256){
        uint256 number = random100();
        if(number < 90){
            return BLUE;
        }
        if(number >= 90 && number < 99){
            return PURPLE;
        }
        if(number >= 99){
            return ORANGE;
        }
        return BLUE;
    }

    function pay() internal{
        require(msg.value >= MoverPrice, "Not enough ETH sent");
        payable(msg.sender).transfer(MoverPrice);
    }

}



contract Clone is MoverCore{
    using Counters for Counters.Counter;

    function public_clone_mint () public payable nonReentrant whenNotPaused{
        require(_tokenIdCounter.current() <= 10000, "Exceed team mint limit");

        _safeMint(_msgSender(), _tokenIdCounter.current());
        payClone();

        public_clone_initial_Mover(_tokenIdCounter.current());
        _tokenIdCounter.increment();
        
    }

    function clone (uint256 token_id) public payable nonReentrant whenNotPaused{
        require(_msgSender() == ownerOf(token_id), "Don't own this token");
        require(!mover[token_id].isClone, "Clone can't clone mover");
        require(_tokenIdCounter.current() <= 10000, "Exceed team mint limit");
        require(mover[token_id].clone > 0, "Don't have enough times to clone");

        _safeMint(_msgSender(), _tokenIdCounter.current());
        payClone();

        clone_initial_Mover(_tokenIdCounter.current());
        mover[token_id].clone = SafeMath.sub(mover[token_id].clone, 1);
        _tokenIdCounter.increment();
        
    }

    function public_clone_initial_Mover(uint256 token_id) internal {
        mover[token_id].level = 1;
        mover[token_id].power = 100;
        mover[token_id].metabolism = 100;
        mover[token_id].coordination = 100;
        mover[token_id].vitality = 50;
        mover[token_id].rarity = public_clone_rarity_determine();
        mover[token_id].isClone = true;
    }

    function public_clone_rarity_determine() view internal returns(uint256){
        uint256 number = random100();
        if(number < 50){
            return GRAY;
        }
        if(number >= 50 && number < 70){
            return GREEN;
        }
        if(number >= 70 && number < 90){
            return BLUE;
        }
        if(number >= 90 && number < 99){
            return PURPLE;
        }
        if(number >= 99){
            return ORANGE;
        }
        return GRAY;
    }


    function clone_initial_Mover(uint256 token_id) internal {
        mover[token_id].level = 1;
        mover[token_id].power = 100;
        mover[token_id].metabolism = 100;
        mover[token_id].coordination = 100;
        mover[token_id].vitality = 50;
        mover[token_id].rarity = clone_rarity_determine(token_id);
        mover[token_id].isClone = true;
    }

    function clone_rarity_determine(uint256 token_id) view internal returns(uint256){
        uint256 number = random100();
        if(mover[token_id].level >= 5 && mover[token_id].level < 10){
            return GRAY;
        }

        if(mover[token_id].level >= 10 && mover[token_id].level < 15){
            uint256 gray_odd = SafeMath.sub(50, SafeMath.div(SafeMath.mul(50, mover[token_id].lucky), 100));
            if(number > gray_odd){
                return GREEN;
            }
            return GRAY;
        }

        if(mover[token_id].level >= 15 && mover[token_id].level < 20){
            uint256 gray_odd = SafeMath.sub(20, SafeMath.div(SafeMath.mul(5, mover[token_id].lucky), 100));
            uint256 green_odd = SafeMath.add(SafeMath.sub(60, SafeMath.div(SafeMath.mul(15, mover[token_id].lucky), 100)), gray_odd);
            if(number > gray_odd && number <= green_odd){
                return GREEN;
            }else if(number > green_odd){
                return BLUE;
            }
            return GRAY;
        }

        if(mover[token_id].level >= 20 && mover[token_id].level < 25){
            uint256 green_odd = SafeMath.sub(40, SafeMath.div(SafeMath.mul(60, mover[token_id].lucky), 100));
            if(number > green_odd){
                return BLUE;
            }
            return GREEN;
        }

        if(mover[token_id].level >= 25 && mover[token_id].level < 30){
            uint256 blue_odd = SafeMath.sub(90, SafeMath.div(SafeMath.mul(10, mover[token_id].lucky), 100));
            if(number > blue_odd){
                return PURPLE;
            }
            return BLUE;
        }

        if(mover[token_id].level == 30){
            uint256 purple_odd = SafeMath.sub(99, SafeMath.div(SafeMath.mul(1, mover[token_id].lucky), 100));
            if(number > purple_odd){
                return ORANGE;
            }
            return PURPLE;
        }
        return GRAY;
    }

    function payClone() internal{
        require(msg.value >= MoverClonePrice, "Not enough ETH sent");
        payable(msg.sender).transfer(MoverPrice);
    }
}






library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract MoverContract is Origin, Clone{

}