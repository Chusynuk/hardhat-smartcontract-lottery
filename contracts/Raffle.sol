// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Raffle
error Raffle_NotEnoughETHEntered();
error Raffle__TransferFailed();

contract Raffle is VRFConsumerBaseV2 {
  // State Variables
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint32 private immutable i_callbackGaslimit;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  // lottery variables

  address private s_recentWinner;
  // Events
  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  constructor(address vrfCoordinatorV2, uint256 entranceFee, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGaslimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_entranceFee = entranceFee;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGaslimit = callbackGaslimit;
  }

  function enterRaffle() public payable {
    if (msg.value < i_entranceFee) {
      revert Raffle_NotEnoughETHEntered();
    }
    s_players.push(payable(msg.sender));

    emit RaffleEnter(msg.sender);
  }

  function requestRandomWinner() external {
    // Request random number
    uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGaslimit, NUM_WORDS);
    emit RequestedRaffleWinner(requestId);
  }

  function fullfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal {}

  // function fullFillRandomWords(
  //   uint256 requestId,
  //   uint256[] memory randomWords
  // ) internal override {}

  // View Pure functions
  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal virtual override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    (bool success, ) = recentWinner.call{value: address(this).balance}("");

    if (!success) {
      revert Raffle__TransferFailed();
    }

    emit WinnerPicked(recentWinner);
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }
}

// Enter the lottery (paying some amount)

//Pick a random winner (verifiably random)

// Winner to be selected every X minutes --> completely automated

// Chainlink Oracle -> Randomness, Automated Execution (ChainLink Keepers)
