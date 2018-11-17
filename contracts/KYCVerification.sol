pragma solidity ^0.4.24;

import "./dappsys/auth.sol";

contract KYCVerification is DSAuth{
    
    mapping(address => bool) public kycAddress;
    
    event LogKYCVerification(address _kycAddress,bool _status);
    
    function addVerified(address[] _kycAddress,bool _status) auth public
    {
        for(uint tmpIndex = 0; tmpIndex <= _kycAddress.length; tmpIndex++)
        {
            kycAddress[_kycAddress[tmpIndex]] = _status;
        }
    }
    
    function updateVerifcation(address _kycAddress,bool _status) auth public
    {
        kycAddress[_kycAddress] = _status;
        
        emit LogKYCVerification(_kycAddress,_status);
    }
    
    function isVerified(address _user) view public returns(bool)
    {
        return kycAddress[_user] == true; 
    }
}
