package {
	import laya.ani.AnimationTemplet;
	import laya.d3.animation.AnimationClip;
	import laya.d3.core.Layer;
	import laya.d3.core.MeshSprite3D;
	import laya.d3.core.PhasorSpriter3D;
	import laya.d3.core.Sprite3D;
	import laya.d3.core.material.PBRMaterial;
	import laya.d3.core.material.StandardMaterial;
	import laya.d3.core.particleShuriKen.ShurikenParticleMaterial;
	import laya.d3.core.render.RenderState;
	import laya.d3.core.scene.OctreeNode;
	import laya.d3.core.scene.Scene;
	import laya.d3.resource.DataTexture2D;
	import laya.d3.resource.Texture2D;
	import laya.d3.resource.TextureCube;
	import laya.d3.resource.models.Mesh;
	import laya.d3.shader.ShaderCompile3D;
	import laya.d3.shader.ShaderInit3D;
	import laya.d3.terrain.TerrainHeightData;
	import laya.d3.terrain.TerrainRes;
	import laya.d3.utils.Utils3D;
	import laya.events.Event;
	import laya.net.Loader;
	import laya.net.LoaderManager;
	import laya.net.URL;
	import laya.renders.Render;
	import laya.utils.Byte;
	import laya.utils.Handler;
	import laya.utils.RunDriver;
	import laya.webgl.WebGL;
	
	/**
	 * <code>Laya3D</code> 类用于初始化3D设置。
	 */
	public class Laya3D {
		/**@private 层级文件资源标记。*/
		private static const HIERARCHY:String = "SPRITE3DHIERARCHY";
		/**@private 网格的原始资源标记。*/
		private static const MESH:String = "MESH";
		/**@private 材质的原始资源标记。*/
		private static const MATERIAL:String = "MATERIAL";
		/**@private PBR材质资源标记。*/
		private static const PBRMATERIAL:String = "PBRMTL";
		/**@private TextureCube原始资源标记。*/
		private static const TEXTURECUBE:String = "TEXTURECUBE";
		/**@private Terrain原始资源标记。*/
		private static const TERRAIN:String = "TERRAIN";
		
		/**@private */
		private static var _DATA:Object = {offset: 0, size: 0};
		/**@private */
		private static var _strings:Array = ['BLOCK', 'DATA', "STRINGS"];//字符串数组
		/**@private */
		private static var _readData:Byte;
		
		/**@private */
		private static const _innerTextureCubeLoaderManager:LoaderManager = new LoaderManager();
		/**@private */
		private static const _innerHeightMapLoaderManager:LoaderManager = new LoaderManager();
		/**@private */
		private static const _innerMaterialLoaderManager:LoaderManager = new LoaderManager();
		/**@private */
		private static const _innerMeshLoaderManager:LoaderManager = new LoaderManager();
		/**@private */
		private static const _innerHierarchyLoaderManager:LoaderManager = new LoaderManager();
		/**@private */
		public static var _debugPhasorSprite:PhasorSpriter3D;
		
		/**@private */
		public static var debugMode:Boolean = false;
		
		/**
		 * 创建一个 <code>Laya3D</code> 实例。
		 */
		public function Laya3D() {
		}
		
		/**
		 *@private
		 */
		private static function _changeWebGLSize(width:Number, height:Number):void {
			WebGL.onStageResize(width, height);
			RenderState.clientWidth = width;
			RenderState.clientHeight = height;
		}
		
		/**
		 *@private
		 */
		private static function _initResourceLoad():void {
			//ClassUtils.regClass("Sprite3D", Sprite3D);
			//ClassUtils.regClass("MeshSprite3D", MeshSprite3D);
			//ClassUtils.regClass("Material", BaseMaterial);
			
			var createMap:Object = LoaderManager.createMap;
			createMap["lh"] = [Sprite3D, Laya3D.HIERARCHY];
			createMap["ls"] = [Scene, Laya3D.HIERARCHY];
			createMap["lm"] = [Mesh, Laya3D.MESH];
			createMap["lmat"] = [StandardMaterial, Laya3D.MATERIAL];
			createMap["lpbr"] = [PBRMaterial, Laya3D.MATERIAL];
			createMap["ltc"] = [TextureCube, Laya3D.TEXTURECUBE];
			createMap["jpg"] = [Texture2D, "nativeimage"];
			createMap["jpeg"] = [Texture2D, "nativeimage"];
			createMap["png"] = [Texture2D, "nativeimage"];
			createMap["lsani"] = [AnimationTemplet, Loader.BUFFER];
			createMap["lrani"] = [AnimationTemplet, Loader.BUFFER];
			createMap["raw"] = [DataTexture2D, Loader.BUFFER];
			createMap["mipmaps"] = [DataTexture2D, Loader.BUFFER];
			createMap["thdata"] = [TerrainHeightData, Loader.BUFFER];
			createMap["lt"] = [TerrainRes, Laya3D.TERRAIN];
			createMap["lani"] = [AnimationClip, Loader.BUFFER];
			createMap["ani"] = [AnimationTemplet, Loader.BUFFER];//兼容接口
			
			Loader.parserMap[Laya3D.HIERARCHY] = _loadHierarchy;
			Loader.parserMap[Laya3D.MESH] = _loadMesh;
			Loader.parserMap[Laya3D.MATERIAL] = _loadMaterial;
			Loader.parserMap[Laya3D.TEXTURECUBE] = _loadTextureCube;
			Loader.parserMap[Laya3D.TERRAIN] = _loadTerrain;
		}
		
		/**
		 *@private
		 */
		private static function READ_BLOCK():Boolean {
			_readData.pos += 4;
			return true;
		}
		
		/**
		 *@private
		 */
		private static function READ_DATA():Boolean {
			_DATA.offset = _readData.getUint32();
			_DATA.size = _readData.getUint32();
			return true;
		}
		
		/**
		 *@private
		 */
		private static function READ_STRINGS():Array {
			var materialUrls:Array = [];
			var _STRINGS:Object = {offset: 0, size: 0};
			_STRINGS.offset = _readData.getUint16();
			_STRINGS.size = _readData.getUint16();
			var ofs:int = _readData.pos;
			_readData.pos = _STRINGS.offset + _DATA.offset;
			
			for (var i:int = 0; i < _STRINGS.size; i++) {
				var string:String = _readData.readUTFString();
				if (string.lastIndexOf(".lmat") !== -1 || string.lastIndexOf(".lpbr") !== -1)
					materialUrls.push(string);
			}
			return materialUrls;
		}
		
		/**
		 *@private
		 */
		private static function _addHierarchyInnerUrls(urls:Array, urlMap:Object, urlVersion:String, hierarchyBasePath:String, path:String, clas:Class):void {
			var formatSubUrl:String = URL.formatURL(path, hierarchyBasePath);
			(urlVersion) && (formatSubUrl = formatSubUrl + urlVersion);
			urls.push({url: formatSubUrl, clas: clas});
			urlMap[path] = formatSubUrl;
		}
		
		/**
		 *@private
		 */
		private static function _getSprite3DHierarchyInnerUrls(node:Object, urls:Array, urlMap:Object, urlVersion:String, hierarchyBasePath:String):void {
			var i:int, n:int;
			switch (node.type) {
			case "Scene": 
				var lightmaps:Array = node.customProps.lightmaps;
				for (i = 0, n = lightmaps.length; i < n; i++) {
					var lightMap:String = lightmaps[i].replace("exr", "png");
					_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, lightMap, Texture2D);//TODO:应该自动序列化类型
				}
				break;
			case "MeshSprite3D": 
				var meshPath:String = node.instanceParams.loadPath;
				(meshPath) && (_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, meshPath, Mesh));
				break;
			case "ShuriKenParticle3D": 
				var customProps:Object = node.customProps;
				var parMeshPath:String = customProps.meshPath;
				(parMeshPath) && (_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, parMeshPath, Mesh));
				var materialPath:String = customProps.materialPath;
				if (materialPath)
					_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, materialPath, ShurikenParticleMaterial);
				else//兼容代码
					_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, customProps.texturePath, Texture2D);
				break;
			case "Terrain": 
				_addHierarchyInnerUrls(urls, urlMap, urlVersion, hierarchyBasePath, node.instanceParams.loadPath, TerrainRes);
				break;
			}
			var children:Array = node.child;
			for (i = 0, n = children.length; i < n; i++)
				_getSprite3DHierarchyInnerUrls(children[i], urls, urlMap, urlVersion, hierarchyBasePath);
		}
		
		/**
		 *@private
		 */
		private static function _loadHierarchy(loader:Loader):void {
			var lmLoader:Loader = new Loader();
			lmLoader.on(Event.COMPLETE, null, _onHierarchylhLoaded, [loader]);
			lmLoader.load(loader.url, Loader.TEXT, false, null, true);
		}
		
		/**
		 *@private
		 */
		private static function _onHierarchylhLoaded(loader:Loader, lhData:String):void {
			var url:String = loader.url;
			var urlVersion:String = Utils3D.getURLVerion(url);
			var hierarchyBasePath:String = URL.getPath(URL.formatURL(url));
			var urls:Array = [];
			var urlMap:Object = {};
			var hierarchyData:Object = JSON.parse(lhData);
			
			_getSprite3DHierarchyInnerUrls(hierarchyData, urls, urlMap, urlVersion, hierarchyBasePath);
			var urlCount:int = urls.length;
			var totalProcessCount:int = urlCount + 1;
			var lhWeight:Number = 1 / totalProcessCount;
			_onProcessChange(loader, 0, lhWeight, 1.0);
			if (urlCount > 0) {
				var processHandler:Handler = Handler.create(null, _onProcessChange, [loader, lhWeight, urlCount / totalProcessCount], false);
				_innerHierarchyLoaderManager.create(urls, Handler.create(null, _onInnerHierarchyResourcesLoaded, [loader, processHandler, lhData, urlMap]), processHandler);
			} else {
				_onInnerHierarchyResourcesLoaded(loader, null, lhData, null);
			}
		}
		
		/**
		 *@private
		 */
		private static function _onInnerHierarchyResourcesLoaded(loader:Loader, processHandler:Handler, lhData:Object, urlMap:Object):void {
			loader.endLoad([lhData, urlMap]);
			(processHandler) && (processHandler.recover());
		}
		
		/**
		 *@private
		 */
		private static function _loadTerrain(loader:Loader):void {
			var ltLoader:Loader = new Loader();
			ltLoader.on(Event.COMPLETE, null, _onTerrainLtLoaded, [loader]);
			ltLoader.load(loader.url, Loader.JSON, false, null, true);
		}
		
		/**
		 *@private
		 */
		private static function _onTerrainLtLoaded(loader:Loader, ltData:Object):void {
			var url:String = loader.url;
			var urlVersion:String = Utils3D.getURLVerion(url);
			var terrainBasePath:String = URL.getPath(URL.formatURL(url));
			
			var heightMapURL:String, textureURLs:Array = [];
			var urlMap:Object = {};
			var formatUrl:String;
			var i:int, n:int, count:uint;
			
			var heightData:Object = ltData.heightData;
			heightMapURL = heightData.url;
			formatUrl = URL.formatURL(heightMapURL, terrainBasePath);
			(urlVersion) && (formatUrl = formatUrl + urlVersion);
			urlMap[heightMapURL] = formatUrl;
			heightMapURL = formatUrl;
			
			var detailTextures:Array = ltData.detailTexture;
			for (i = 0, n = detailTextures.length; i < n; i++) {
				textureURLs.push(detailTextures[i].diffuse);
			}
			
			var normalMaps:Array = ltData.normalMap;
			for (i = 0, n = normalMaps.length; i < n; i++) {
				textureURLs.push(normalMaps[i]);
			}
			
			var alphaMaps:Array = ltData.alphaMap;
			for (i = 0, n = alphaMaps.length; i < n; i++) {
				textureURLs.push(alphaMaps[i]);
			}
			
			
			for (i = 0, n = textureURLs.length; i < n; i++) {
				var subUrl:String = textureURLs[i];
				formatUrl = URL.formatURL(subUrl, terrainBasePath);
				(urlVersion) && (formatUrl = formatUrl + urlVersion);
				textureURLs[i] = formatUrl;
				urlMap[subUrl] = formatUrl;
			}
			
			var texsUrlCount:int = textureURLs.length;
			var totalProcessCount:int = texsUrlCount + 2;//heightMap始终为1个
			var weight:Number = 1 / totalProcessCount;
			_onProcessChange(loader, 0, weight, 1.0);
			
			var loadInfo:Object = {heightMapLoaded: false, texturesLoaded: false};
			var hmProcessHandler:Handler = Handler.create(null, _onProcessChange, [loader, weight, weight], false);
			_innerHeightMapLoaderManager.create(heightMapURL, Handler.create(null, _onTerrainHeightMapLoaded, [loader, hmProcessHandler, ltData, urlMap, loadInfo]), hmProcessHandler, null, [heightData.numX, heightData.numZ, heightData.bitType, heightData.value]);
			
			var texsProcessHandler:Handler = Handler.create(null, _onProcessChange, [loader, weight * 2, texsUrlCount / totalProcessCount], false);
			_innerTextureCubeLoaderManager.create(textureURLs, Handler.create(null, _onTerrainTexturesLoaded, [loader, texsProcessHandler, ltData, urlMap, loadInfo]), texsProcessHandler);
		}
		
		/**
		 *@private
		 */
		private static function _onTerrainHeightMapLoaded(loader:Loader, processHandler:Handler, ltData:Object, urlMap:Object, loadInfo:Object):void {
			loadInfo.heightMapLoaded = true;
			if (loadInfo.texturesLoaded) {
				loader.endLoad([ltData, urlMap]);
				processHandler.recover();
			}
		}
		
		/**
		 *@private
		 */
		private static function _onTerrainTexturesLoaded(loader:Loader, processHandler:Handler, ltData:Object, urlMap:Object, loadInfo:Object):void {
			loadInfo.texturesLoaded = true;
			if (loadInfo.heightMapLoaded) {
				loader.endLoad([ltData, urlMap]);
				processHandler.recover();
			}
		}
		
		/**
		 *@private
		 */
		private static function _loadMesh(loader:Loader):void {
			var lmLoader:Loader = new Loader();
			lmLoader.on(Event.COMPLETE, null, _onMeshLmLoaded, [loader]);
			lmLoader.load(loader.url, Loader.BUFFER, false, null, true);
		}
		
		/**
		 *@private
		 */
		private static function _onMeshLmLoaded(loader:Loader, lmData:ArrayBuffer):void {
			var url:String = loader.url;
			var urlVersion:String = Utils3D.getURLVerion(url);
			var meshBasePath:String = URL.getPath(URL.formatURL(url));
			
			var urls:Array;
			var urlMap:Object = {};
			var formatSubUrl:String;
			
			var i:int, n:int, count:uint;
			_readData = new Byte(lmData);
			_readData.pos = 0;
			var version:String = _readData.readUTFString();
			switch (version) {
			case "LAYAMODEL:02": 
				var dataOffset:uint = _readData.getUint32();
				_readData.pos = _readData.pos + 4;//跳过数据信息区
				
				count = _readData.getUint16();//跳过内容段落信息区
				_readData.pos = _readData.pos + count * 8;
				
				var offset:uint = _readData.getUint32();//读取字符区
				count = _readData.getUint16();
				_readData.pos = dataOffset + offset;
				
				urls = [];
				for (i = 0; i < count; i++) {
					var string:String = _readData.readUTFString();
					if (string.lastIndexOf(".lmat") !== -1)
						urls.push(string);
				}
				break;
			default: 
				READ_BLOCK();
				for (i = 0; i < 2; i++) {
					var index:int = _readData.getUint16();
					var blockName:String = _strings[index];
					var fn:Function = Laya3D["READ_" + blockName];
					if (fn == null) throw new Error("model file err,no this function:" + index + " " + blockName);
					
					if (i === 1)
						urls = fn.call();
					else
						fn.call()
				}
				
			}
			
			for (i = 0, n = urls.length; i < n; i++) {
				var subUrl:String = urls[i];
				formatSubUrl = URL.formatURL(subUrl, meshBasePath);
				(urlVersion) && (formatSubUrl = formatSubUrl + urlVersion);
				urls[i] = formatSubUrl;
				urlMap[subUrl] = formatSubUrl;
			}
			
			var urlCount:int = 1;
			var totalProcessCount:int = urlCount + 1;
			var lmatWeight:Number = 1 / totalProcessCount;
			_onProcessChange(loader, 0, lmatWeight, 1.0);
			var processHandler:Handler = Handler.create(null, _onProcessChange, [loader, lmatWeight, urlCount / totalProcessCount], false);
			_innerMeshLoaderManager.create(urls, Handler.create(null, _onMeshMateialLoaded, [loader, processHandler, lmData, urlMap]), processHandler/*, StandardMaterial*/);
		}
		
		/**
		 *@private
		 */
		private static function _onMeshMateialLoaded(loader:Loader, processHandler:Handler, lmData:Object, urlMap:Object):void {
			loader.endLoad([lmData, urlMap]);
			processHandler.recover();
		}
		
		/**
		 *@private
		 */
		public static function _getMaterialTexturePath(path:String, urlVersion:String, materialBath:String):String {
			var extenIndex:int = path.length - 4;
			if (path.indexOf(".dds") == extenIndex || path.indexOf(".tga") == extenIndex || path.indexOf(".exr") == extenIndex || path.indexOf(".DDS") == extenIndex || path.indexOf(".TGA") == extenIndex || path.indexOf(".EXR") == extenIndex)
				path = path.substr(0, extenIndex) + ".png";
		
			path = URL.formatURL(path, materialBath);
			(urlVersion) && (path = path + urlVersion);
			return path;
		}
		
		/**
		 *@private
		 */
		private static function _loadMaterial(loader:Loader):void {
			var lmatLoader:Loader = new Loader();
			lmatLoader.on(Event.COMPLETE, null, _onMaterilLmatLoaded, [loader]);
			lmatLoader.load(loader.url, Loader.JSON, false, null, true);
		}
		
		/**
		 *@private
		 */
		private static function _onMaterilLmatLoaded(loader:Loader, lmatData:Object):void {
			var url:String = loader.url;
			var urlVersion:String = Utils3D.getURLVerion(url);
			var materialBasePath:String = URL.getPath(URL.formatURL(url));
			var urls:Array = [];
			var urlMap:Object = {};
			var customProps:Object = lmatData.customProps;
			var formatSubUrl:String;
			var version:String = lmatData.version;
			if (version) {
				switch (version) {
				case "LAYAMATERIAL:01": 
					var textures:Array = lmatData.props.textures;
					for (var i:int = 0, n:int = textures.length; i < n; i++) {
						var path:String = textures[i].path;
						if (path) {
							formatSubUrl = _getMaterialTexturePath(path, urlVersion, materialBasePath);
							urls.push(formatSubUrl);
							urlMap[path] = formatSubUrl;
						}
					}
					break;
				default: 
					throw new Error("Laya3D:unkonwn version.");
				}
			} else {//兼容性代码
				var diffuseTexture:String = customProps.diffuseTexture.texture2D;
				if (diffuseTexture) {
					formatSubUrl = _getMaterialTexturePath(diffuseTexture, urlVersion, materialBasePath);
					urls.push(formatSubUrl);
					urlMap[diffuseTexture] = formatSubUrl;
				}
				
				if (customProps.normalTexture) {
					var normalTexture:String = customProps.normalTexture.texture2D;
					if (normalTexture) {
						formatSubUrl = _getMaterialTexturePath(normalTexture, urlVersion, materialBasePath);
						urls.push(formatSubUrl);
						urlMap[normalTexture] = formatSubUrl;
					}
				}
				
				if (customProps.specularTexture) {
					var specularTexture:String = customProps.specularTexture.texture2D;
					if (specularTexture) {
						formatSubUrl = _getMaterialTexturePath(specularTexture, urlVersion, materialBasePath);
						urls.push(formatSubUrl);
						urlMap[specularTexture] = formatSubUrl;
					}
				}
				
				if (customProps.emissiveTexture) {
					var emissiveTexture:String = customProps.emissiveTexture.texture2D;
					if (emissiveTexture) {
						formatSubUrl = _getMaterialTexturePath(emissiveTexture, urlVersion, materialBasePath);
						urls.push(formatSubUrl);
						urlMap[emissiveTexture] = formatSubUrl;
					}
				}
				
				if (customProps.ambientTexture) {
					var ambientTexture:String = customProps.ambientTexture.texture2D;
					if (ambientTexture) {
						formatSubUrl = _getMaterialTexturePath(ambientTexture, urlVersion, materialBasePath);
						urls.push(formatSubUrl);
						urlMap[ambientTexture] = formatSubUrl;
					}
				}
				
				if (customProps.reflectTexture) {
					var reflectTexture:String = customProps.reflectTexture.texture2D;
					if (reflectTexture) {
						formatSubUrl = _getMaterialTexturePath(reflectTexture, urlVersion, materialBasePath);
						urls.push(formatSubUrl);
						urlMap[reflectTexture] = formatSubUrl;
					}
				}
			}
			
			var urlCount:int = urls.length;
			var totalProcessCount:int = urlCount + 1;
			var lmatWeight:Number = 1 / totalProcessCount;
			_onProcessChange(loader, 0, lmatWeight, 1.0);
			if (urlCount > 0) {
				var processHandler:Handler = Handler.create(null, _onProcessChange, [loader, lmatWeight, urlCount / totalProcessCount], false);
				_innerMaterialLoaderManager.create(urls, Handler.create(null, _onMateialTexturesLoaded, [loader, processHandler, lmatData, urlMap]), processHandler, Texture2D);//TODO:还有可能是TextureCube
			} else {
				_onMateialTexturesLoaded(loader, null, lmatData, null);
			}
		
		}
		
		/**
		 *@private
		 */
		private static function _onMateialTexturesLoaded(loader:Loader, processHandler:Handler, lmatData:Object, urlMap:Object):void {
			loader.endLoad([lmatData, urlMap]);
			(processHandler) && (processHandler.recover());
		}
		
		/**
		 *@private
		 */
		private static function _loadTextureCube(loader:Loader):void {
			var ltcLoader:Loader = new Loader();
			ltcLoader.on(Event.COMPLETE, null, _onTextureCubeLtcLoaded, [loader]);
			ltcLoader.load(loader.url, Loader.JSON, false, null, true);
		}
		
		/**
		 *@private
		 */
		private static function _onTextureCubeLtcLoaded(loader:Loader, ltcData:Object):void {
			var ltcBasePath:String = URL.getPath(URL.formatURL(loader.url));
			var urls:Array = [URL.formatURL(ltcData.px, ltcBasePath), URL.formatURL(ltcData.nx, ltcBasePath), URL.formatURL(ltcData.py, ltcBasePath), URL.formatURL(ltcData.ny, ltcBasePath), URL.formatURL(ltcData.pz, ltcBasePath), URL.formatURL(ltcData.nz, ltcBasePath)];
			var ltcWeight:Number = 1.0 / 7.0;
			_onProcessChange(loader, 0, ltcWeight, 1.0);
			var processHandler:Handler = Handler.create(null, _onProcessChange, [loader, ltcWeight, 6 / 7], false);
			_innerTextureCubeLoaderManager.load(urls, Handler.create(null, _onTextureCubeImagesLoaded, [loader, urls, processHandler]), processHandler, "nativeimage");
		}
		
		/**
		 *@private
		 */
		private static function _onTextureCubeImagesLoaded(loader:Loader, urls:Array, processHandler:Handler):void {
			var images:Array = [];
			images.length = 6;
			for (var i:int = 0; i < 6; i++) {
				var url:String = urls[i];
				images[i] = Loader.getRes(url);
				Loader.clearRes(url);
			}
			loader.endLoad(images);
			processHandler.recover();
		}
		
		/**
		 *@private
		 */
		private static function _onProcessChange(loader:Loader, offset:Number, weight:Number, process:Number):void {
			process = offset + process * weight;
			(process < 1.0) && (loader.event(Event.PROGRESS, process));
		}
		
		/**
		 * 初始化Laya3D相关设置。
		 * @param	width  3D画布宽度。
		 * @param	height 3D画布高度。
		 */
		public static function init(width:Number, height:Number, antialias:Boolean = false, alpha:Boolean = false, premultipliedAlpha:Boolean = true, stencil:Boolean = true):void {
			Config.isAntialias = antialias;
			Config.isAlpha = alpha;
			Config.premultipliedAlpha = premultipliedAlpha;
			Config.isStencil = stencil;
			
			if (!Render.isConchNode && !WebGL.enable()) {
				alert("Laya3D init error,must support webGL!");
				return;
			}
			
			RunDriver.changeWebGLSize = _changeWebGLSize;
			Render.is3DMode = true;
			_innerTextureCubeLoaderManager.maxLoader = 1;
			_innerMaterialLoaderManager.maxLoader = 1;
			_innerMeshLoaderManager.maxLoader = 1;
			_innerHierarchyLoaderManager.maxLoader = 1;
			Laya.init(width, height);
			Layer.__init__();
			ShaderCompile3D.__init__();
			ShaderInit3D.__init__();
			MeshSprite3D.__init__();
			_initResourceLoad();
			
			if (Laya3D.debugMode || OctreeNode.debugMode)
				_debugPhasorSprite = new PhasorSpriter3D();
		}
	
	}
}