{ config, lib, pkgs, ... }:
let
	inherit (lib)
		mkOption
		mkEnableOption
		mkPackageOption
		mkMerge
		mkIf
		types
		getExe
		mapAttrsToList
		mapAttrs
		concatStringsSep
		escapeShellArg
		filterAttrs
		optionalAttrs
	;

	enabledWebsites = filterAttrs (_: website: website.enable) config.websites;
in
{
	options = {
		websites = mkOption {
			default = { };
			description = "Hosted websites.";
			type = types.attrsOf (types.submodule ({ name, ... }: {
				options = {
					enable = mkEnableOption "${name} website.";

					package = mkPackageOption pkgs name { };

					user = mkOption {
						type = types.str;
						default = name;
						description = "User account under which ${name} website runs.";
					};

					group = mkOption {
						type = types.str;
						default = name;
						description = "Group under which ${name} website runs.";
					};

					environment = mkOption {
						type = types.attrsOf types.str;
						default = { };
						description = "Environment variables for the ${name} website service.";
					};

					environmentToEvaluate = mkOption {
						type = types.attrsOf types.str;
						default = { };
						description = "Environment variables for the ${name} website service that need to be evaluated.";
					};
				};
			}));
		};
	};

	config = mkIf (enabledWebsites != { }) {
		users = {
			users = mkMerge (
				mapAttrsToList (name: website:
					optionalAttrs (website.user == name) {
						${name} = {
							isSystemUser = true;
							group = website.group;
							description = "${name} website service user";
						};
					}
				) enabledWebsites
			);

			groups = mkMerge (
				mapAttrsToList (name: website:
					optionalAttrs (website.group == name) {
						${name} = { };
					}
				) enabledWebsites
			);
		};


		systemd.services = mapAttrs (name: website: {
			description = "${name} website";
			after = [ "network-online.target" ];
			wants = [ "network-online.target" ];
			wantedBy = [ "multi-user.target" ];
			path = [ website.package ];

			serviceConfig = {
				User = name;
				Group = name;
				WorkingDirectory = "${website.package}/share";
				ExecStart = pkgs.writeShellScript "start-${name}" ''
					${concatStringsSep "\n" (mapAttrsToList
						(key: value: "export ${key}=$(cat ${escapeShellArg value})")
						website.environmentToEvaluate)}

					exec ${getExe website.package}
				'';
				Restart = "always";
			};

			environment = website.environment;
		}) enabledWebsites;
	};
}
