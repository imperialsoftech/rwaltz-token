pragma solidity ^0.4.24;

import "./dappsys/math.sol";
import "./dappsys/token.sol";
import "./dappsys/auth.sol";


contract RwaltzCrowdSale is DSAuth, DSMath {

    uint public MIN_FUNDING = 1000 ether;  // min funding soft-cap
    uint public MAX_FUNDING =  1000 ether;  // contribution hard-cap 1000 ether;
    uint public MIN_CONTRIBUTION = 0.1 ether;
    
    
    DSToken public RwaltzToken;         // RwaltzToken token contract
    address public beneficiary;       // destination to collect eth deposits

    uint public startTime;           // start block of sale
    uint public endTime;             // end block of sale

    uint public totalEthDeposited;    // sums of ether raised
    uint public totalTokensBought;    // total tokens issued on sale
    uint public totalEthCollected;    // total eth collected from sale
    uint public totalEthRefunded;     // total eth refunded after a failed sale
    
    mapping (bytes32 => uint) public totalEthDepositsViaOtherCurrency; //Deposits via BTC, LTC etc
    
    // buyers ether deposits
    mapping (address => uint) public ethDeposits;
    mapping (address => uint) public ethDepositsViaOtherCurrency;

    // ether refunds after a failed sale
    mapping (address => uint) public ethRefunds;

    enum State {Pending,Running,Succeeded,Failed}
    
    State public state = State.Pending;

    uint public tokensPerEth ;
    
    struct Milestone {
        uint8 id;
          // UNIX timestamp when this milestone kicks in
        uint start;
          // UNIX timestamp when this milestone kicks out
        uint end;
          // How many % tokens will add
        uint bonus;
    }
    
    Milestone[] public milestones;
    
    // uint256[] preIcoBonuses = [25];
  
    /*******************************  Events *************************************/
    event LogBuy(address indexed buyer,uint ethDeposit,uint tokensBought,uint bonusToken);
    event LogBuyViaOtherCurrency(address indexed buyer,uint ethDeposit,bytes32 viaCurrency, bytes32 viaCurrencyAmt, bytes32 gatewayTxId, uint tokensBought,uint bonusToken);

    event LogRefund(address indexed buyer,uint ethRefund);
    event LogStartSale(uint startTime,uint endTime);
    event LogEndSale(bool success,uint totalEthDeposited,uint totalTokensBought);
    event LogExtendSale(uint endTime);
    event LogCollectEth(uint ethCollected,uint totalEthDeposited);
    event LogBonusAdd(uint id,uint startTime,uint endTime,uint percent);
    event LogBonusUpdate(uint8 milestoneId,uint _percent);
    event LogHardcapUpdate(uint _MAX_FUNDING);
    event LogExchangeRateUpdate(uint _tokensPerEth);

    /*******************************  Modifiers ***********************************/

    // check given state of sale
    
    modifier saleIn(State state_) { require(state_ == state); _; }

    // check current block is inside closed interval [startBlock, endBlock]
    modifier inRunningBlock() {
        require(now >= startTime);
        require(now <= endTime);
        _;
    }

    // check sender has sent some ethers
    modifier ethSent() { require(msg.value > 0); _; }

    

    /*******************************  Public Methods *********************************/

    constructor (DSToken RwaltzToken_, 
                 address beneficiary_,
                 uint _tokensPerEth) public
    {
        RwaltzToken = RwaltzToken_;
        beneficiary = beneficiary_;
        tokensPerEth = _tokensPerEth;
        
        /* Contract in State Pending */
        state = State.Pending;
        
    }

    function() public payable 
    {
        buyTokens();
    }

    function buyTokens() saleIn(State.Running) inRunningBlock ethSent public payable 
    {
        require(msg.value >= MIN_CONTRIBUTION);
        /* Caluclate Tokens for Purchase */
        uint tokensBought = calcTokensForPurchase(msg.value);
        
        /* Add Bonus to Tokens Bought */
        
        uint _bonusToken = wdiv(wmul(tokensBought, getCurrentMilestone().bonus), 100);
        tokensBought += _bonusToken;
        
        ethDeposits[msg.sender] = add(msg.value, ethDeposits[msg.sender]);
        
        totalEthDeposited = add(msg.value, totalEthDeposited);
        totalTokensBought = add(tokensBought, totalTokensBought);

        require(totalEthDeposited <= MAX_FUNDING);

        RwaltzToken.mint(msg.sender, tokensBought);

        emit LogBuy(msg.sender, msg.value, tokensBought,_bonusToken);
    }

  
    /********************** Authentication required ******************************/
    function buyTokensWithOtherCurrency(address reciever, uint ethInWei, bytes32 viaCurrency,bytes32 viaCurrencyAmt,bytes32 gatewayTxId) 
            saleIn(State.Running) inRunningBlock auth public
    {
        require(ethInWei >= MIN_CONTRIBUTION);
        uint tokensBought = calcTokensForPurchase(ethInWei);

        /* Add Bonus */
        uint _bonusToken = wdiv(wmul(tokensBought, getCurrentMilestone().bonus), 100);
        tokensBought += _bonusToken;

        /*  Log User Deposits  */
        ethDepositsViaOtherCurrency[reciever] = add(ethInWei, ethDepositsViaOtherCurrency[reciever]);
        
        /*  Log in Other Deposits */
        totalEthDepositsViaOtherCurrency[viaCurrency] = add(ethInWei, totalEthDepositsViaOtherCurrency[viaCurrency]);

        /*  Log Tokens Bought  */
        totalTokensBought = add(tokensBought, totalTokensBought);

        require(totalEthDeposited <= MAX_FUNDING);

        /*  Mint Tokens  */
        RwaltzToken.mint(reciever, tokensBought);

        emit LogBuy(reciever, ethInWei, tokensBought,_bonusToken);
        emit LogBuyViaOtherCurrency(reciever, ethInWei, viaCurrency, viaCurrencyAmt, gatewayTxId, tokensBought,_bonusToken);
    } 

    function startSale(uint _startTime, uint _endTime) auth saleIn(State.Pending) public
    {
        // require(_startTime >= now);
        require(startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;
    
        state      = State.Running;
        
        /* Milestone Bonus List Here */
        milestones.push(Milestone(1,_startTime, _endTime, 25));
        emit LogBonusAdd(1,_startTime,_endTime,25);

        emit LogStartSale(startTime, endTime);
    }

    function endSale() auth saleIn(State.Running) public
    {
        state = State.Succeeded;
        
        emit LogEndSale(state == State.Succeeded, totalEthDeposited, totalTokensBought);
    }

    function extendSale(uint _endTime) auth saleIn(State.Running) public
    {
        require(_endTime > endTime);

        endTime = _endTime;
        emit LogExtendSale(endTime);
    }

    function collectEth() auth public
    {
        /* Cannot be Called BEfore Min Funding */
        require(totalEthDeposited >= MIN_FUNDING);
        require(address(this).balance > 0);

        uint ethToCollect = address(this).balance;
        totalEthCollected = add(totalEthCollected, ethToCollect);
        address(beneficiary).transfer(ethToCollect);
        
        emit LogCollectEth(ethToCollect, totalEthDeposited);
    }
    
    function updateBonusPercent(uint8 _id,uint _percent) auth  saleIn(State.Running) public
    {
        milestones[getMilestoneIndexById(_id)].bonus = _percent;
        
        emit LogBonusUpdate(_id,_percent);
    }
    
    function updateHardcap(uint _MAX_FUNDING) auth saleIn(State.Running) public
    {
        MAX_FUNDING = _MAX_FUNDING;
        
        emit LogHardcapUpdate(MAX_FUNDING);
    }

    function updateSoftcap(uint _MIN_FUNDING) auth saleIn(State.Running) public
    {
        MIN_FUNDING = _MIN_FUNDING;
        
        emit LogHardcapUpdate(MIN_FUNDING);
    }
    
    function updateExchangeRate(uint _tokensPerEth) auth saleIn(State.Running) public
    {
        tokensPerEth = _tokensPerEth;
        
        emit LogExchangeRateUpdate(tokensPerEth);
    }
    
    function getCurrentMilestoneIndex() public constant returns (uint) 
    {
        for (uint i = 0; i < milestones.length; i++) 
        {
            if (milestones[i].start <= now && milestones[i].end > now) 
            {
              return i;
            }
        }
    }

    /********************** Private Methods ******************************/

    // calculate number of tokens buyer get when sending 'ethSent' ethers
    // after 'ethDepostiedSoFar` already reeived in the sale
    function calcTokensForPurchase(uint ethSentByUser) private view returns (uint tokens)
    {
        return wmul(ethSentByUser, tokensPerEth);
    }
    
    function getCurrentMilestone() private constant returns (Milestone) 
    {
        for (uint i = 0; i < milestones.length; i++) 
        {
            if (milestones[i].start <= now && milestones[i].end > now) 
            {
              return milestones[i];
            }
        }
    }
    
    function getMilestoneIndexById(uint8 _id) private constant returns (uint) 
    {
        for (uint i = 0; i < milestones.length; i++) 
        {
            if (milestones[i].id == _id) 
            {
              return i;
            }
        }
    }

    

    
}
