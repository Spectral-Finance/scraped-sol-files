// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    OfferItem,
    ConsiderationItem,
    SpentItem,
    AdvancedOrder,
    OrderParameters,
    CriteriaResolver,
    FulfillmentComponent
} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, TraitRedemption} from "../lib/RedeemablesStructs.sol";

interface IRedeemableContractOfferer {
    /* Events */
    event CampaignUpdated(uint256 indexed campaignId, CampaignParams params, string metadataURI);
    event Redemption(uint256 indexed campaignId, bytes32 redemptionHash);

    /* Getters */
    function getCampaign(uint256 campaignId)
        external
        view
        returns (CampaignParams memory params, string memory metadataURI, uint256 totalRedemptions);

    /* Setters */
    function createCampaign(CampaignParams calldata params, string calldata metadataURI)
        external
        returns (uint256 campaignId);

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata metadataURI) external;
}
