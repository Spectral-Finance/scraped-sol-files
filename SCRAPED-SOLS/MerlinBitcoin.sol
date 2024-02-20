// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

contract MerlinBitcoin is ERC20  {
    // bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() ERC20("Merlin Bitcoin", "mBTC"){
        // _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        // _mint(msg.sender, 21000000*10^8);
    }

    // function addMinter(address minter_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _grantRole(MINT_ROLE, minter_);
    // }

    // function rmMinter(address minter_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _revokeRole(MINT_ROLE, minter_);
    // }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    // function mint(address account, uint256 amount) public onlyRole(MINT_ROLE) {
    //     _mint(account, amount);
    // }
}
