// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ImpactScore, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {ERC721, ERC721Enumerable, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";

event ProjectUpdated(uint256 indexed projectId, string projectURI, ImpactScore impactScore);
event CreEntrypointSet(address indexed creEntrypoint);
event Whitelisted(address indexed account, bool status);

error NotCreEntrypoint();
error NotWhitelisted();

contract ProjectMod is ERC721Enumerable, ERC721URIStorage, Ownable, IProjectMod {
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    address private creEndpoint;
    mapping(uint256 => ImpactScore) private projectScores;
    mapping(address => bool) private whitelist;

    //*//////////////////////////////////////////////////////////////////////////
    //                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*//

    constructor(address _owner) ERC721("", "") {
        _initializeOwner(_owner);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyCRE() {
        if (_msgSender() != creEndpoint) revert NotCreEntrypoint();
        _;
    }

    modifier onlyWhitelisted() {
        if (!whitelist[_msgSender()]) revert NotWhitelisted();
        _;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function setCreEntrypointAddress(address _creEndpoint) external onlyOwner {
        creEndpoint = _creEndpoint;
        emit CreEntrypointSet(_creEndpoint);
    }

    function setWhitelist(address _account, bool _status) external onlyOwner {
        whitelist[_account] = _status;
        emit Whitelisted(_account, _status);
    }

    function createProject(string calldata _projectURI) external onlyWhitelisted returns (uint256 projectId_) {
        projectId_ = totalSupply() + 1;
        _mint(_msgSender(), projectId_);
        _setTokenURI(projectId_, _projectURI);
        emit ProjectUpdated(projectId_, _projectURI, ImpactScore(0, 0));
    }

    function updateProjects(ProjectDetails[] calldata _projectDetails) external onlyCRE {
        uint256 length = _projectDetails.length;
        for (uint256 i; i < length; ++i) {
            _updateProject(_projectDetails[i].projectId, _projectDetails[i].projectURI, _projectDetails[i].impactScore);
        }
    }

    function getCreEntrypointAddress() external view returns (address) {
        return creEndpoint;
    }

    function getProjectScore(uint256 _projectId) external view returns (ImpactScore memory) {
        _requireOwned(_projectId);
        return projectScores[_projectId];
    }

    function getProjectScores() external view returns (ImpactScore[] memory projectScores_) {
        uint256 length = totalSupply();
        projectScores_ = new ImpactScore[](length);
        for (uint256 i; i < length; ++i) {
            projectScores_[i] = projectScores[i + 1];
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Returns the token collection name.
    function name() public view virtual override returns (string memory) {
        return "Ecobond Projects";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual override returns (string memory) {
        return "EBP";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override(ERC721Enumerable, IProjectMod) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return ERC721Enumerable._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _updateProject(uint256 _projectId, string calldata _projectURI, ImpactScore calldata _impactScore)
        private
    {
        projectScores[_projectId] = _impactScore;
        _setTokenURI(_projectId, _projectURI);
        emit ProjectUpdated(_projectId, _projectURI, _impactScore);
    }
}
