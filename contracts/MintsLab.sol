// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interface/IMintsLab.sol";
import "./NFTshop.sol";

contract MintsLabFactory is IMintsLab {
    address wallet;
    address dev;
    uint256 govShare;

    function governanceDetails()
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (wallet, dev, govShare);
    }

    function checkRoyality(uint256 ftype) external view override returns (bool status, uint256 _ftype) {}

    function createNFTshop(string calldata name, string calldata symbol) external returns (address _shop) {
        _shop = address(new NFTstore(name, symbol));
    }
}
