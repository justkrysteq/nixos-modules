{
	description = "Krysteq's Additional NixOS Modules";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

		# home-manager = {
		# 	url = "github:nix-community/home-manager";
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };
	};

	outputs = { nixpkgs, ... }:

	{
		nixosModules = {
			default = import ./modules;

			brave = import ./modules/brave.nix;
			websites = import ./modules/websites.nix;
		};
	};
}
