/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.24;

import "./stop.sol";
import "./base.sol";
import "../KYCVerification.sol";

contract DSToken is DSTokenBase(0), DSStop {

    mapping (address => mapping (address => bool)) _trusted;

    // Optional token name
    string  public  name = "";
    string  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    bool public kycEnabled = true;

    KYCVerification public kycVerification;
    
    constructor (string name_,string symbol_,KYCVerification _kycAddress) public {
        name = name_;
        symbol = symbol_;
        
        kycVerification = _kycAddress;
    }

    event Trust(address indexed src, address indexed guy, bool wat);
    event Burn(address indexed guy, uint wad);
    event KYCMandateUpdate(bool _kycEnabled);
    
    modifier kycVerified(address _guy) {

        if(kycEnabled == true)
        {
            if(kycVerification.isVerified(_guy) == false)
            {
                revert("KYC Not Verified");
            }
        }
        _;
    }
    
    function updateKycMandate(bool _kycEnabled) public auth
    {
        kycEnabled = _kycEnabled;
        emit KYCMandateUpdate(_kycEnabled);
    }

    function trusted(address src, address guy) public view returns (bool) {
        return _trusted[src][guy];
    }
    function trust(address guy, bool wat) public stoppable {
        _trusted[msg.sender][guy] = wat;
        emit Trust(msg.sender, guy, wat);
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }
    
    function transfer(address dst, uint wad) public stoppable kycVerified(msg.sender) returns (bool) {
        
        return super.transfer(dst,wad);
    }
    
    
    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && !_trusted[src][msg.sender]) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        
        emit Transfer(address(0),address(this),wad);
        emit Transfer(address(this),guy,wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && !_trusted[guy][msg.sender]) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }

    

    function setName(string name_) public auth {
        name = name_;
    }
}
