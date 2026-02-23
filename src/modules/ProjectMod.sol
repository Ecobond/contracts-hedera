// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ImpactScore, ProjectDetails} from "../interfaces/IProjectMod.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";

event ProjectUpdated(uint256 projectId, string projectURI, ImpactScore impactScore);
event CreEntrypointSet(address creEntrypoint);
error NotCreEntrypoint();

contract ProjectMod is ERC721Enumerable, ERC721URIStorage, Ownable, IProjectMod {
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    address private creEndpoint;
    mapping(uint256 => ImpactScore) private projectScores;

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

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function setCreEntrypointAddress(address _creEndpoint) external onlyOwner {
        creEndpoint = _creEndpoint;
    }

    function getCreEntrypointAddress() external view returns (address) {
        return creEndpoint;
        emit CreEntrypointSet(_creEndpoint);
    }

    function createProject(string calldata _projectURI) external returns (uint256 projectId_) {
        projectId_ = totalSupply() + 1;
        _mint(_msgSender(), projectId_);
        _setTokenURI(projectId_, _projectURI);
        emit ProjectUpdated(projectId_, _projectURI, ImpactScore(0, 0));
    }

    function updateProjects(uint256[] calldata _projectIds, string[] calldata _projectURIs) external onlyCRE {
        uint256 length = _projectIds.length;
        if (length != _projectURIs.length) revert NotCreEntrypoint();
        for (uint256 i; i < length; ++i) {
            _updateProject(_projectIds[i], _projectURIs[i]);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Returns the token collection name.
    function name() public view virtual override returns (string memory) {
        return "Green Bond Projects";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual override returns (string memory) {
        return "GBP";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function _updateProject(uint256 _projectId, string calldata _projectURI) private {
    //*//////////////////////////////////////////////////////////////////////////
    //                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

        _setTokenURI(_projectId, _projectURI);
        emit ProjectUpdated(_projectId, _projectURI, _impactScore);
    }
}
