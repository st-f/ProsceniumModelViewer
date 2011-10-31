package View
{
	import com.adobe.display.Color;
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.MaterialData;
	import com.adobe.scenegraph.loaders.ModelLoader;
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.kmz.KMZLoader;
	import com.adobe.scenegraph.loaders.obj.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.dns.AAAARecord;
	import flash.ui.Keyboard;
	import flash.utils.*;
	
	public class OBJScene extends BasicDemo
	{
		protected static const SKYBOX_DIRECTORY:String				= "../assets/skybox/";
		protected static const SKYBOX_FILENAMES:Vector.<String>		= new <String>[
			SKYBOX_DIRECTORY + "px.png",
			SKYBOX_DIRECTORY + "nx.png",
			SKYBOX_DIRECTORY + "py.png",
			SKYBOX_DIRECTORY + "ny.png",
			SKYBOX_DIRECTORY + "pz.png",
			SKYBOX_DIRECTORY + "nz.png"
		];
		
		protected var _modelURL:String;
		public var yaw:Boolean = false;
		public var pitch:Boolean = false;
		public var roll:Boolean = false;
		public var rotateX:Boolean = false;
		public var rotateY:Boolean = false;
		public var rotateZ:Boolean = false;
		public var rotationSpeed:Number = 1;
		public var cameraLookAtEnabled:Boolean = true;
		
		protected var _modelScale:Number = 0.1;		
		protected var _sky:SceneSkyBox;
		protected var _modelLoaderOBJ:OBJLoader;
		protected var _modelLoaderDAE:ColladaLoader;
		protected var _modelLoaderKMZ:KMZLoader;
		
		protected var fileExtAry:Array;
		protected var fileExt:String;
		
		private var keyRight   :Boolean = false;
		private var keyLeft    :Boolean = false;
		private var keyForward :Boolean = false;
		private var keyReverse :Boolean = false;
		
		public function OBJScene()
		{
			super();
			shadowMapEnabled = true;
			SceneGraph.OIT_ENABLED = true;
		}
		
		override protected function initHandlers():void
		{
			super.initHandlers();
		}
		
		override protected function initLights():void
		{
			var material:MaterialStandard;
			
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			light = new SceneLight(SceneLight.KIND_DISTANT, "distant light");
			light.color.set(.9, .88, .85);
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize(shadowMapSize, shadowMapSize);
			light.transform.prependRotation(-75, Vector3D.X_AXIS);
			light.transform.prependRotation(-35, Vector3D.Y_AXIS);
			light.transform.appendTranslation(0.1, 20, 0.1);
			lights.push(light);
			
			light = new SceneLight();
			light.color.set(.25, .22, .20);
			light.kind = "distant";
			light.appendRotation(-90, Vector3D.Y_AXIS, ORIGIN);
			light.appendRotation(45, Vector3D.Z_AXIS, ORIGIN);			
			lights.push(light);
			
			for each (light in lights)
			{
				scene.addChild(light);
			}
			SceneLight.shadowMapZBiasFactor		  			= 0;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 2;
			material = new MaterialStandard("light2");
			material.emissiveColor = light.color;
		}
		
		public function resetModel():void
		{
			if(modelSceneNode)
			{
				modelSceneNode.transform = new Matrix3D();
				modelSceneNode.appendScale(_modelScale,_modelScale,_modelScale);
			}
		}
		
		public function rotate(axis:String, value:Number):void
		{
			if(axis == "X")
			{
				//var rotateMatrix:Matrix3D = new Matrix3D(1,0,0,1, 0,1,0,1, 0,0,1,1, 0,0,0,1);
				var scaleX:Number = _modelScale;
				var scaleY:Number = _modelScale;
				var scaleZ:Number = _modelScale;
				var v:Vector.<Number> = new Vector.<Number>;
				for(var i:int = 0; i < 16; i++)
				{
					v[i] = 0;
				}
				//v[3] = 1;
				//v[5] = 1;
				//v[10] = 1;
				modelSceneNode.transform = new Matrix3D(v);
				modelSceneNode.appendRotation(value, Vector3D.X_AXIS);
				trace("Rotate "+axis+" value: "+value);
			}
		}
		
		override protected function onAnimate(t:Number, dt:Number):void 
		{
			if(!modelSceneNode) return;
			if(rotateX)
			{
				modelSceneNode.appendRotation(rotationSpeed, Vector3D.X_AXIS);
			}
			if(rotateY) 
			{	
				modelSceneNode.appendRotation(rotationSpeed, Vector3D.Y_AXIS);
			}
			if(rotateZ) 
			{	
				modelSceneNode.appendRotation(rotationSpeed, Vector3D.Z_AXIS);
			}
			if(yaw)
			{
				modelSceneNode.eulerRotate(0,rotationSpeed,0);
			}
			if(roll)
			{
				modelSceneNode.eulerRotate(0,0,rotationSpeed);
			}
			if(pitch)
			{
				modelSceneNode.eulerRotate(rotationSpeed,0,0);
			}
			if(cameraLookAtEnabled) _camera.lookat(_camera.position, modelSceneNode.position, Vector3D.Y_AXIS);
		}
		
		override protected function initModels():void
		{
			init();
		}

		public function init():void
		{
			var material:MaterialStandard = new MaterialStandard();
			material.opacity = 0.3;
			var model:SceneMesh = MeshUtils.createPlane(100, 100, 20, 20, material, "plane");
			scene.addChild(model);
			LoadTracker.loadImages(SKYBOX_FILENAMES, imageLoadComplete);
		}
		
		protected function imageLoadComplete(bitmaps:Dictionary):void
		{
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>(6, true);
			var bitmap:Bitmap;
			for (var i:uint = 0; i < 6; i++)
				bitmapDatas[ i ] = bitmaps[ SKYBOX_FILENAMES[ i ] ].bitmapData;
			
			_sky = new SceneSkyBox(bitmapDatas, false);
			scene.addChild(_sky);	// skybox must be an immediate child of scene root
			_sky.name = "Sky";
			setupModel();
		}
		
		public function setupModel():void
		{
			trace("LOAD NEW MODEL: "+_modelURL+" FILE TYPE: "+fileExt);
			if(scene.getChildByName("ModelSceneNode"))
			{
				trace("LOAD NEW MODEL, REMOVING EXISTING MODEL");
				scene.removeChild(modelSceneNode);
			}
			if(fileExt)
			{
				switch(fileExt)
				{
					case "obj":
						_modelLoaderOBJ = new OBJLoader(_modelURL);
						_modelLoaderOBJ.addEventListener(Event.COMPLETE, loadComplete);
						break;
					case "dae":
						_modelLoaderDAE = new ColladaLoader(_modelURL);
						_modelLoaderDAE.addEventListener(Event.COMPLETE, loadComplete);
						break;
					case "kmz":
						_modelLoaderKMZ = new KMZLoader(_modelURL);
						_modelLoaderKMZ.addEventListener(Event.COMPLETE, loadComplete);
						break;
					default:
						trace("ERROR: TYPE NOT RECOGNIZED");
				}
			}
		}
		
		protected var modelSceneNode:SceneNode;
		protected var manifest:ModelManifest;
		protected var materialData:MaterialData;
		
		protected function loadComplete(event:Event):void
		{
			var material:MaterialStandard = new MaterialStandard();
			material.specularColor.set(.5, .5, .5);
			material.bump = 2;
			material.specularExponent = 25;
			modelSceneNode = new SceneNode("ModelSceneNode");
			materialData = new MaterialData("testmaterial");
			
			switch(fileExt)
			{
				case "obj":
					manifest = _modelLoaderOBJ.model.addTo(modelSceneNode);
					_modelLoaderOBJ.model.materials.push(materialData);
					_modelScale = _modelLoaderOBJ.model.scale;
					trace("_modelLoaderOBJ.model.scale : "+_modelLoaderOBJ.model.scale);
					break;
				case "dae":
					manifest = _modelLoaderDAE.model.addTo(modelSceneNode);
					_modelLoaderDAE.model.materials.push(materialData);
					_modelScale = _modelLoaderDAE.model.scale;
					trace("_modelLoaderDAE.model.scale : "+_modelLoaderDAE.model.scale);
					break;
				case "kmz":
					manifest = _modelLoaderKMZ.model.addTo(modelSceneNode);
					_modelLoaderKMZ.model.materials.push(materialData);
					_modelScale = _modelLoaderKMZ.model.scale;
					trace("_modelLoaderKMZ.model.scale : "+_modelLoaderKMZ.model.scale);
					break;
				default:
			}
			
			scene.addChild(modelSceneNode);

			var boundingW:Number = modelSceneNode.boundingBox.maxX - modelSceneNode.boundingBox.minX;
			var boundingH:Number = modelSceneNode.boundingBox.maxY - modelSceneNode.boundingBox.minY;
			if(boundingW > 10)
			{
				_modelScale = 10 / boundingW;
			}
/*			trace("NEW MODEL LOADED: "+_modelURL);
			trace("NEW MODEL LOADED: "+" boundingW "+boundingW+" boundingH: "+boundingH+" scale: "+_modelScale);*/
			//modelSceneNode.appendScale(_modelScale,_modelScale,_modelScale);
			//var futureY:Number = (modelSceneNode.boundingBox.maxY - modelSceneNode.boundingBox.minY);
			//modelSceneNode.move(modelSceneNode.boundingBox.centerX, modelSceneNode.boundingBox.centerY, modelSceneNode.boundingBox.centerZ);
			/*trace("NEW MODEL LOADED: "+" maxY: "+modelSceneNode.boundingBox.maxY+" minY: "+modelSceneNode.boundingBox.minY+" scale: "+_modelScale);
			trace("NEW MODEL LOADED: "+" futureY: "+futureY+" center: "+modelSceneNode.boundingBox.centerY+" scale: "+_modelScale);*/
			
			resetModel();
			
			lights[0].addToShadowMap(scene);
			
			
			//_camera.lookat(_camera.position, modelSceneNode.position, Vector3D.Y_AXIS);
			//trace("NEW MODEL LOADED: "+scene);
		}
		
		protected function keyDownHandler(event :KeyboardEvent):void
		{
			trace("keyDownHandler: "+event.keyCode);
			switch(event.keyCode)
			{
				case "W".charCodeAt():
				case Keyboard.UP:
					keyForward = true;
					keyReverse = false;
					break;
				
				case "S".charCodeAt():
				case Keyboard.DOWN:
					keyReverse = true;
					keyForward = false;
					break;
				
				case "A".charCodeAt():
				case Keyboard.LEFT:
					keyLeft = true;
					keyRight = false;
					break;
				
				case "D".charCodeAt():
				case Keyboard.RIGHT:
					keyRight = true;
					keyLeft = false;
					break;
			}
		}
			
		protected function keyUpHandler(event :KeyboardEvent):void
		{
			trace("keyUpHandler: "+event.keyCode);
			switch(event.keyCode)
			{
				case "W".charCodeAt():
				case Keyboard.UP:
					keyForward = false;
					break;
				
				case "S".charCodeAt():
				case Keyboard.DOWN:
					keyReverse = false;
					break;
				
				case "A".charCodeAt():
				case Keyboard.LEFT:
					keyLeft = false;
					break;
				
				case "D".charCodeAt():
				case Keyboard.RIGHT:
					keyRight = false;
					break;
			}
		}

		public function get modelURL():String
		{
			return _modelURL;
		}

		public function set modelURL(value:String):void
		{
			_modelURL = value;
			fileExtAry = _modelURL.split(".");
			fileExt = String(fileExtAry[fileExtAry.length-1]).toLowerCase();
		}

		public function get modelScale():Number
		{
			return _modelScale;
		}

		public function set modelScale(value:Number):void
		{
			_modelScale = value;
			trace("SCALING: "+_modelScale+" model: "+modelSceneNode)
			if(modelSceneNode)
			{
				modelSceneNode.transform.appendScale(_modelScale,_modelScale,_modelScale);
				modelSceneNode.setPosition(0,0,0);
			}
		}


	}
}