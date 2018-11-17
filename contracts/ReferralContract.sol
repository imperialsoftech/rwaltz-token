pragma solidity ^0.4.24;

import './dappsys/token.sol';
import './dappsys/auth.sol';

contract ReferralContract is DSAuth{
    uint public bonusToken;
	uint public totalDispersedToken;


	mapping(address => mapping(address => uint)) public referralList; 
	DSToken public zeosXToken;


	event BonusDispersed(address indexed referrer_eth_address,address indexed target_eth_address,uint bonusAmount);
	event BonusAmountUpdated(uint _bonusToken);

	constructor(DSToken _zeosXToken,uint _bonusToken) public
	{
		zeosXToken = _zeosXToken;
		bonusToken = _bonusToken;
	}

	function setBonusToken(uint _bonusToken) auth public
	{
		bonusToken = _bonusToken;

		emit BonusAmountUpdated(_bonusToken);
	}

	function disperseBonus(address _referrer_eth_address,address _target_eth_address) auth public returns (bool)
	{
		require(referralList[_referrer_eth_address][_target_eth_address] == 0);


		/* Issue tokens */

		zeosXToken.mint(_target_eth_address, bonusToken);

		referralList[_referrer_eth_address][_target_eth_address] = bonusToken;
		totalDispersedToken+=bonusToken;

		/* Emit event */
		emit BonusDispersed(_referrer_eth_address,_target_eth_address,bonusToken);
		
		return true;
	}
}