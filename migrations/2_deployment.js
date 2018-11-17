var RwaltzToken = artifacts.require('./DSToken.sol');
var RwaltzPrivatePreSale = artifacts.require('./RwaltzPrivatePreSale.sol');
var RwaltzPublicPreSale = artifacts.require('./RwaltzPublicPreSale.sol');
var RwaltzCrowdSale = artifacts.require('./RwaltzCrowdSale.sol');
var KYCVerification = artifacts.require('./KYCVerification.sol');
var ReferralContract = artifacts.require('./ReferralContract.sol');



var metaData = {
	RwaltzPrivatePreSale:{
		beneficiary: "0xab0874cB61D83F6B67Dc08141568868102233bef",
		// tokensPerEth: "5500000000000000000000"
		tokensPerEth: "500000000000000000000"
	},
	RwaltzPublicPreSale:{
		beneficiary: "0xab0874cB61D83F6B67Dc08141568868102233bef",
		tokensPerEth: "5500000000000000000000"
	},
	RwaltzCrowdSale:{
		beneficiary: "0xab0874cB61D83F6B67Dc08141568868102233bef",
		tokensPerEth: "5500000000000000000000"
	}
}




module.exports = async function(deployer) {

	/*Deploy Ztoken */
	deployer.deploy(KYCVerification)
	.then(()=>{
		return deployer.deploy(RwaltzToken, "Rwaltz", "Rwaltz", KYCVerification.address)
	})
	.then(()=>{
		
		/*Deploy RwaltzPrivatePreSale */
		return  deployer.deploy(RwaltzPrivatePreSale,
	  						RwaltzToken.address,
	  						metaData.RwaltzPrivatePreSale.beneficiary,
	  						metaData.RwaltzPrivatePreSale.tokensPerEth);
	})
	.then(()=>{
		
		/*Deploy RwaltzPublicPreSale */
		return  deployer.deploy(RwaltzPublicPreSale,
	  						RwaltzToken.address,
	  						metaData.RwaltzPublicPreSale.beneficiary,
	  						metaData.RwaltzPublicPreSale.tokensPerEth);
	})
	.then(()=>{
		
		/*Deploy RwaltzCrowdSale */
		return  deployer.deploy(RwaltzCrowdSale,
	  						RwaltzToken.address,
	  						metaData.RwaltzCrowdSale.beneficiary,
	  						metaData.RwaltzCrowdSale.tokensPerEth);
	})
	.then(()=>{
		/*Deploy ReferralContract */
		return  deployer.deploy(ReferralContract,
	  						RwaltzToken.address,
	  						"50000000000000000000");
	})
	.then(()=>{
		
		/*Deploy KYCVerification */
		return  Promise.all([
					KYCVerification.deployed(),
					RwaltzToken.deployed(),
					RwaltzPrivatePreSale.deployed(),
					RwaltzPublicPreSale.deployed(),
					RwaltzCrowdSale.deployed()
				]);
	})

	.then(async([KYCVerificationInstance,RwaltzTokenInstance,RwaltzPrivatePreSaleInstance,RwaltzPublicPreSaleInstance,RwaltzCrowdSaleInstance]) => {
		
		await KYCVerificationInstance.setAuthority(RwaltzToken.address);
		await KYCVerificationInstance.setAuthority(RwaltzPrivatePreSale.address);
		await KYCVerificationInstance.setAuthority(RwaltzPublicPreSale.address);
		await KYCVerificationInstance.setAuthority(RwaltzCrowdSale.address);


		/* Set Authority for enabling access of RwaltzToken to RwaltzPrivatePreSale */
		await RwaltzTokenInstance.setAuthority(RwaltzPrivatePreSale.address);
		/* Set Authority for enabling access of RwaltzToken to RwaltzPublicPreSale */
	  	await RwaltzTokenInstance.setAuthority(RwaltzPublicPreSale.address);
	  	/* Set Authority for enabling access of RwaltzToken to RwaltzCrowdSale */
		await RwaltzTokenInstance.setAuthority(RwaltzCrowdSale.address);
		/* Set Authority for enabling access of RwaltzToken to ReferralContract */
		await RwaltzTokenInstance.setAuthority(ReferralContract.address);


		 // Set Start Sale and Update Whitelisting for Sample Users  
		 // 1533808058 = 08/09/2018 @ 9:47am (UTC)
		 // 1565568000 = 08/12/2019 @ 12:00am (UTC)

		// await RwaltzPrivatePreSaleInstance.startSale(parseInt(new Date().getTime()/1000),1565568000);	
		
		/* await RwaltzPrivatePreSaleInstance.updateWhiteListing("0xa2aae4985fa3ccb8af6094a245914baee49822f3",true);
		await RwaltzPrivatePreSaleInstance.updateWhiteListing("0x36fefe201706e2056fd01844030415f78840b2d8",true);
		await RwaltzPrivatePreSaleInstance.updateWhiteListing("0x9f386ccd8a8e7043314902ece639de8e2452d731",true); */

		 // Set Start Sale 
		 // 1533808058 = 08/09/2018 @ 9:47am (UTC)
		 // 1565568000 = 08/12/2019 @ 12:00am (UTC)

		// await RwaltzPublicPreSaleInstance.startSale(parseInt(new Date().getTime()/1000),1565568000);	

		 // Set Start Sale 
		 // 1533808058 = 08/09/2018 @ 9:47am (UTC)
		 // 1565568000 = 08/12/2019 @ 12:00am (UTC)

		// await RwaltzCrowdSaleInstance.startSale(parseInt(new Date().getTime()/1000),1565568000);	

		return KYCVerificationInstance;
	});
};
