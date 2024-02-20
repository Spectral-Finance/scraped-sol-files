// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// LooksRare unopinionated libraries
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

// Core contracts
import {ITransferManager, TransferManager} from "../../contracts/TransferManager.sol";
import {AmountInvalid, LengthsInvalid} from "../../contracts/errors/SharedErrors.sol";

// Mocks and other utils
import {MockERC20} from "../mock/MockERC20.sol";
import {MockERC721} from "../mock/MockERC721.sol";
import {MockERC1155} from "../mock/MockERC1155.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

// Enums
import {TokenType} from "../../contracts/enums/TokenType.sol";

contract TransferManagerTest is TestHelpers, TestParameters {
    event ApprovalsGranted(address user, address[] operators);
    event ApprovalsRemoved(address user, address[] operators);
    event OperatorAllowed(address operator);
    event OperatorRemoved(address operator);

    address[] public operators;
    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    TransferManager public transferManager;

    uint256 private constant tokenIdERC721 = 55;
    uint256 private constant tokenId1ERC1155 = 1;
    uint256 private constant amount1ERC1155 = 2;
    uint256 private constant tokenId2ERC1155 = 2;
    uint256 private constant amount2ERC1155 = 5;
    uint256 private constant amountERC20 = 100e18;

    /**
     * 0. Internal helper functions
     */

    function _grantApprovals(address user) private asPrankedUser(user) {
        mockERC20.approve(address(transferManager), type(uint256).max);
        mockERC721.setApprovalForAll(address(transferManager), true);
        mockERC1155.setApprovalForAll(address(transferManager), true);
        address[] memory approvedOperators = new address[](1);
        approvedOperators[0] = _transferrer;

        vm.expectEmit({checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsGranted(user, approvedOperators);
        transferManager.grantApprovals(approvedOperators);
    }

    function _allowOperator(address transferrer) private {
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorAllowed(transferrer);
        transferManager.allowOperator(transferrer);
    }

    function setUp() public asPrankedUser(_owner) {
        transferManager = new TransferManager(_owner);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();
        operators.push(_transferrer);

        vm.deal(_transferrer, 100 ether);
        vm.deal(_sender, 100 ether);
    }

    /**
     * 1. Happy cases
     */

    function test_TransferERC20() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        vm.prank(_sender);
        mockERC20.mint(_sender, amountERC20);

        vm.prank(_transferrer);
        transferManager.transferERC20(address(mockERC20), _sender, _recipient, amountERC20);

        assertEq(mockERC20.balanceOf(_recipient), amountERC20);
    }

    function test_TransferItemERC721() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 500;

        vm.prank(_sender);
        mockERC721.mint(_sender, itemId);

        vm.prank(_transferrer);
        transferManager.transferItemERC721(address(mockERC721), _sender, _recipient, itemId);

        assertEq(mockERC721.ownerOf(itemId), _recipient);
    }

    function test_TransferItemsERC721_Single() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 500;

        vm.prank(_sender);
        mockERC721.mint(_sender, itemId);

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(_transferrer);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);

        assertEq(mockERC721.ownerOf(itemId), _recipient);
    }

    function test_TransferItemERC1155() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 1;
        uint256 amount = 2;

        mockERC1155.mint(_sender, itemId, amount);

        vm.prank(_transferrer);
        transferManager.transferItemERC1155(address(mockERC1155), _sender, _recipient, itemId, amount);

        assertEq(mockERC1155.balanceOf(_recipient, itemId), amount);
    }

    function test_TransferItemsERC1155_Single() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 1;
        uint256 amount = 2;

        mockERC1155.mint(_sender, itemId, amount);

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        vm.prank(_transferrer);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);

        assertEq(mockERC1155.balanceOf(_recipient, itemId), amount);
    }

    function test_TransferItemsERC721_Batch() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        uint256[] memory itemIds = new uint256[](2);
        itemIds[0] = tokenId1;
        itemIds[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        mockERC721.batchMint(_sender, itemIds);

        vm.prank(_transferrer);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);

        assertEq(mockERC721.ownerOf(tokenId1), _recipient);
        assertEq(mockERC721.ownerOf(tokenId2), _recipient);
    }

    function test_TransferItemsERC1155_Batch() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 tokenId1 = 1;
        uint256 amount1 = 2;
        uint256 tokenId2 = 2;
        uint256 amount2 = 5;

        mockERC1155.mint(_sender, tokenId1, amount1);
        mockERC1155.mint(_sender, tokenId2, amount2);

        uint256[] memory itemIds = new uint256[](2);
        itemIds[0] = tokenId1;
        itemIds[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        vm.prank(_transferrer);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);

        assertEq(mockERC1155.balanceOf(_recipient, tokenId1), amount1);
        assertEq(mockERC1155.balanceOf(_recipient, tokenId2), amount2);
    }

    function test_TransferBatchItemsAcrossCollections() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();

        vm.prank(_transferrer);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);

        assertEq(mockERC721.ownerOf(tokenIdERC721), _recipient);
        assertEq(mockERC1155.balanceOf(_recipient, tokenId1ERC1155), amount1ERC1155);
        assertEq(mockERC1155.balanceOf(_recipient, tokenId2ERC1155), amount2ERC1155);
        assertEq(mockERC20.balanceOf(_recipient), amountERC20);
    }

    function test_TransferBatchItemsAcrossCollections_ByOwner() public asPrankedUser(_sender) {
        mockERC20.approve(address(transferManager), type(uint256).max);
        mockERC721.setApprovalForAll(address(transferManager), true);
        mockERC1155.setApprovalForAll(address(transferManager), true);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();

        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);

        assertEq(mockERC721.ownerOf(tokenIdERC721), _recipient);
        assertEq(mockERC1155.balanceOf(_recipient, tokenId1ERC1155), amount1ERC1155);
        assertEq(mockERC1155.balanceOf(_recipient, tokenId2ERC1155), amount2ERC1155);
        assertEq(mockERC20.balanceOf(_recipient), amountERC20);
    }

    /**
     * 2. Revertion patterns
     */
    function test_TransferERC20_RevertIf_AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferERC20(address(mockERC20), _sender, _recipient, 0);
    }

    function test_TransferItemsERC721_RevertIf_AmountIsNotOne(uint256 amount) public {
        vm.assume(amount != 1);

        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 500;

        mockERC721.mint(_sender, itemId);

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);
    }

    function test_TransferItemERC1155_Single_RevertIf_AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 500;

        mockERC1155.mint(_sender, itemId, 1);

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferItemERC1155(address(mockERC1155), _sender, _recipient, itemId, 0);
    }

    function test_TransferItemsERC1155_Single_RevertIf_AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemId = 500;

        mockERC1155.mint(_sender, itemId, 1);

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);
    }

    function test_TransferItemsERC1155_Multiple_RevertIf_AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        uint256 itemIdOne = 500;
        uint256 itemIdTwo = 501;

        mockERC1155.mint(_sender, itemIdOne, 1);
        mockERC1155.mint(_sender, itemIdTwo, 1);

        uint256[] memory itemIds = new uint256[](2);
        itemIds[0] = itemIdOne;
        itemIds[1] = itemIdTwo;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = 0;

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ZeroLength() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = new ITransferManager.BatchTransferItem[](0);

        vm.expectRevert(LengthsInvalid.selector);
        vm.prank(_transferrer);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ERC721AmountIsNotOne(uint256 amount) public {
        vm.assume(amount != 1);

        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[1].amounts[0] = amount;

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_sender);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ERC1155AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[0].amounts[0] = 0;

        vm.expectRevert(AmountInvalid.selector);
        vm.prank(_sender);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ERC20ItemIdsLengthIsNotZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[2].itemIds = new uint256[](1);

        vm.prank(_transferrer);
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ERC20AmountsLengthIsNotOne() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[2].amounts = new uint256[](0);

        vm.prank(_transferrer);
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);

        items[2].amounts = new uint256[](2);

        vm.prank(_transferrer);
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_ERC20AmountIsZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[2].amounts[0] = 0;

        vm.prank(_transferrer);
        vm.expectRevert(AmountInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);

        items[2].amounts = new uint256[](2);

        vm.prank(_transferrer);
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_PerCollectionItemIdsLengthZero() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();
        items[0].itemIds = new uint256[](0);
        items[0].amounts = new uint256[](0);

        vm.prank(_transferrer);
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferItemERC721_RevertIf_OperatorApprovalsRevokedByUserOrOperatorRemovedByOwner() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        // 1. User revokes the operator
        vm.prank(_sender);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsRemoved(_sender, operators);
        transferManager.revokeApprovals(operators);

        uint256 itemId = 500;

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemERC721(address(mockERC721), _sender, _recipient, itemId);

        // 2. Sender grants again approvals but owner removes the operators
        _grantApprovals(_sender);
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorRemoved(_transferrer);
        transferManager.removeOperator(_transferrer);

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemERC721(address(mockERC721), _sender, _recipient, itemId);
    }

    function test_TransferItemsERC721_RevertIf_OperatorApprovalsRevokedByUserOrOperatorRemovedByOwner() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        // 1. User revokes the operator
        vm.prank(_sender);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsRemoved(_sender, operators);
        transferManager.revokeApprovals(operators);

        uint256 itemId = 500;
        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);

        // 2. Sender grants again approvals but owner removes the operators
        _grantApprovals(_sender);
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorRemoved(_transferrer);
        transferManager.removeOperator(_transferrer);

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);
    }

    function test_TransferItemERC1155_RevertIf_OperatorApprovalsRevokedByUserOrOperatorRemovedByOwner() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        // 1. User revokes the operator
        vm.prank(_sender);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsRemoved(_sender, operators);
        transferManager.revokeApprovals(operators);

        uint256 itemId = 500;
        uint256 amount = 5;

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemERC1155(address(mockERC1155), _sender, _recipient, itemId, amount);

        // 2. Sender grants again approvals but owner removes the operators
        _grantApprovals(_sender);
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorRemoved(_transferrer);
        transferManager.removeOperator(_transferrer);

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemERC1155(address(mockERC1155), _sender, _recipient, itemId, amount);
    }

    function test_TransferItemsERC1155_RevertIf_OperatorApprovalsRevokedByUserOrOperatorRemovedByOwner() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        // 1. User revokes the operator
        vm.prank(_sender);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsRemoved(_sender, operators);
        transferManager.revokeApprovals(operators);

        uint256 itemId = 500;
        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5;

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);

        // 2. Sender grants again approvals but owner removes the operators
        _grantApprovals(_sender);
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorRemoved(_transferrer);
        transferManager.removeOperator(_transferrer);

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);
    }

    function test_TransferBatchItemsAcrossCollections_RevertIf_OperatorApprovalsRevoked() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        // 1. User revokes the operator
        vm.prank(_sender);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ApprovalsRemoved(_sender, operators);
        transferManager.revokeApprovals(operators);

        ITransferManager.BatchTransferItem[] memory items = _generateValidBatchTransferItems();

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);

        // 2. Sender grants again approvals but owner removes the operators
        _grantApprovals(_sender);
        vm.prank(_owner);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit OperatorRemoved(_transferrer);
        transferManager.removeOperator(_transferrer);

        vm.prank(_transferrer);
        vm.expectRevert(ITransferManager.TransferCallerInvalid.selector);
        transferManager.transferBatchItemsAcrossCollections(items, _sender, _recipient);
    }

    function test_TransferItemsERC721OrERC1155_RevertIf_ArrayLengthIsZero() public {
        uint256[] memory emptyArrayUint256 = new uint256[](0);

        // 1. ERC721
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferItemsERC721(
            address(mockERC721),
            _sender,
            _recipient,
            emptyArrayUint256,
            emptyArrayUint256
        );

        // 2. ERC1155 length is 0
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferItemsERC1155(
            address(mockERC1155),
            _sender,
            _recipient,
            emptyArrayUint256,
            emptyArrayUint256
        );
    }

    function test_TransferItemsERC721OrERC1155_RevertIf_ArrayLengthDiffers() public {
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](3);

        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferItemsERC721(address(mockERC721), _sender, _recipient, itemIds, amounts);

        vm.expectRevert(LengthsInvalid.selector);
        transferManager.transferItemsERC1155(address(mockERC1155), _sender, _recipient, itemIds, amounts);
    }

    function test_GrantOrRevokeApprovals_RevertIf_ArrayLengthIs0() public {
        address[] memory emptyArrayAddresses = new address[](0);

        // 1. Grant approvals
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.grantApprovals(emptyArrayAddresses);

        // 2. Revoke approvals
        vm.expectRevert(LengthsInvalid.selector);
        transferManager.revokeApprovals(emptyArrayAddresses);
    }

    function test_GrantApproval_RevertIf_OperatorOperatorNotAllowed() public asPrankedUser(_owner) {
        address randomOperator = address(420);
        transferManager.allowOperator(randomOperator);
        vm.expectRevert(ITransferManager.OperatorAlreadyAllowed.selector);
        transferManager.allowOperator(randomOperator);
    }

    function test_AllowOperator_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        transferManager.allowOperator(address(0));
    }

    function test_AllowOperator_RevertIf_OperatorAlreadyAllowed() public asPrankedUser(_owner) {
        address randomOperator = address(420);
        transferManager.allowOperator(randomOperator);
        vm.expectRevert(ITransferManager.OperatorAlreadyAllowed.selector);
        transferManager.allowOperator(randomOperator);
    }

    function test_RemoveOperator_RevertIf_OperatorNotAllowed() public asPrankedUser(_owner) {
        address notOperator = address(420);
        vm.expectRevert(ITransferManager.OperatorNotAllowed.selector);
        transferManager.removeOperator(notOperator);
    }

    function test_GrantApprovals_RevertIf_OperatorNotAllowed() public {
        address[] memory approvedOperators = new address[](1);
        approvedOperators[0] = _transferrer;

        vm.expectRevert(ITransferManager.OperatorNotAllowed.selector);
        vm.prank(_sender);
        transferManager.grantApprovals(approvedOperators);
    }

    function test_GrantApprovals_RevertIf_OperatorAlreadyApprovedByUser() public {
        _allowOperator(_transferrer);
        _grantApprovals(_sender);

        address[] memory approvedOperators = new address[](1);
        approvedOperators[0] = _transferrer;

        vm.expectRevert(ITransferManager.OperatorAlreadyApprovedByUser.selector);
        vm.prank(_sender);
        transferManager.grantApprovals(approvedOperators);
    }

    function test_RevokeApprovals_RevertIf_OperatorNotApprovedByUser() public {
        address[] memory approvedOperators = new address[](1);
        approvedOperators[0] = _transferrer;

        vm.expectRevert(ITransferManager.OperatorNotApprovedByUser.selector);
        vm.prank(_sender);
        transferManager.revokeApprovals(approvedOperators);
    }

    function test_RemoveOperator_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        transferManager.removeOperator(address(0));
    }

    function _generateValidBatchTransferItems() private returns (ITransferManager.BatchTransferItem[] memory items) {
        items = new ITransferManager.BatchTransferItem[](3);

        {
            mockERC721.mint(_sender, tokenIdERC721);
            mockERC1155.mint(_sender, tokenId1ERC1155, amount1ERC1155);
            mockERC1155.mint(_sender, tokenId2ERC1155, amount2ERC1155);
            mockERC20.mint(_sender, amountERC20);

            uint256[] memory tokenIdsERC1155 = new uint256[](2);
            tokenIdsERC1155[0] = tokenId1ERC1155;
            tokenIdsERC1155[1] = tokenId2ERC1155;

            uint256[] memory amountsERC1155 = new uint256[](2);
            amountsERC1155[0] = amount1ERC1155;
            amountsERC1155[1] = amount2ERC1155;

            uint256[] memory tokenIdsERC721 = new uint256[](1);
            tokenIdsERC721[0] = tokenIdERC721;

            uint256[] memory amountsERC721 = new uint256[](1);
            amountsERC721[0] = 1;

            uint256[] memory amountsERC20 = new uint256[](1);
            amountsERC20[0] = amountERC20;

            items[0] = ITransferManager.BatchTransferItem({
                tokenAddress: address(mockERC1155),
                tokenType: TokenType.ERC1155,
                itemIds: tokenIdsERC1155,
                amounts: amountsERC1155
            });
            items[1] = ITransferManager.BatchTransferItem({
                tokenAddress: address(mockERC721),
                tokenType: TokenType.ERC721,
                itemIds: tokenIdsERC721,
                amounts: amountsERC721
            });
            items[2] = ITransferManager.BatchTransferItem({
                tokenAddress: address(mockERC20),
                tokenType: TokenType.ERC20,
                itemIds: new uint256[](0),
                amounts: amountsERC20
            });
        }
    }
}
