package com.as3nui.nativeExtensions.air.kinect.examples.basic
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.constants.JointIndices;
	import com.as3nui.nativeExtensions.air.kinect.data.KinectCapabilities;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.bit101.components.CheckBox;
	import com.bit101.components.ComboBox;
	import com.bit101.components.Text;
	import com.bit101.components.Window;
	import com.bit101.utils.MinimalConfigurator;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.describeType;

	public class BasicDemo extends DemoBase
	{
		public static const KinectMaxDepthInFlash:uint = 200;

		private var kinect:Kinect;
		private var rgbBitmap:Bitmap;
		private var depthBitmap:Bitmap;
		
		private var rgbSkeletonContainer:Sprite;
		private var depthSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;

		public var wnd_stats:Window;
		public var chk_rgbMirror:CheckBox;
		public var chk_depthMirror:CheckBox;
		public var chk_skeletonMirror:CheckBox;

		public var cmb_jointList:ComboBox;

		public var txt_worldX:Text;
		public var txt_worldY:Text;
		public var txt_worldZ:Text;

		public var txt_worldRelativeX:Text;
		public var txt_worldRelativeY:Text;
		public var txt_worldRelativeZ:Text;

		public var txt_rgbX:Text;
		public var txt_rgbY:Text;
		public var txt_rgbRelativeX:Text;
		public var txt_rgbRelativeY:Text;

		public var txt_depthX:Text;
		public var txt_depthY:Text;
		public var txt_depthRelativeX:Text;
		public var txt_depthRelativeY:Text;
		private var currentStatsJoint:String;

		override protected function startDemoImplementation():void
		{
			trace("[BasicDemo] startDemoImplementation");
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				depthSkeletonContainer = new Sprite();
				addChild(depthSkeletonContainer);
				
				skeletonContainer = new Sprite();
				addChild(skeletonContainer);
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.rgbEnabled = true;

				config.depthEnabled = true;
				config.depthShowUserColors = true;
				config.skeletonEnabled = true;
				
				kinect.start(config);

				initUI(config);

				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}

		private function initUI(kConfig:KinectConfig):void {
			var config:MinimalConfigurator = new MinimalConfigurator(this);

			var mainLayout:XML = <comps>
				<Window title="Position Stats" id="wnd_stats" width="850" height="150">
					<HBox spacing="20" x = "10" y = "10">
							<VBox>
								<ComboBox id="cmb_jointList"/>
								<CheckBox label="RGB Mirror" id="chk_rgbMirror" event="click:onChkClick"/>
								<CheckBox label="Depth Mirror" id="chk_depthMirror" event="click:onChkClick"/>
								<CheckBox label="Skeleton Mirror" id="chk_skeletonMirror" event="click:onChkClick"/>
							</VBox>
					</HBox>
				</Window>
				<Window title="Capabilities" id="wnd_capabilities" x="250" y = "10" width="300" height="350" minimized="true" hasMinimizeButton="true">
						<VBox spacing="2" x="10" y="10"/>
				</Window>
			</comps>;

			var kinectCapabilities:KinectCapabilities = Kinect.Capabilities;
			var capability:String;
			for each(var capabilityXML:XML in describeType(kinectCapabilities)..accessor) {
				capability = capabilityXML.@name.toString();
				var value:String = kinectCapabilities[capability].toString();
				var lblXML:XML = <Label text={capability + " :: " + value}/>;
				mainLayout..Window.(@id =="wnd_capabilities").VBox.appendChild(lblXML);
			}

			mainLayout..Window.(@id =="wnd_stats").HBox.appendChild(getUIPanel("world"));
			mainLayout..Window.(@id =="wnd_stats").HBox.appendChild(getUIPanel("rgb"));
			mainLayout..Window.(@id =="wnd_stats").HBox.appendChild(getUIPanel("depth"));
			config.parseXML(mainLayout);


			for(var i:uint = 0; i < JointIndices.JOINT_LOOKUP.length; i++)
			{
				cmb_jointList.addItem({label:JointIndices.JOINT_LOOKUP[i], data:JointIndices.JOINT_LOOKUP[i]})
			}
			//Default to left hand
			cmb_jointList.selectedIndex = JointIndices.LEFT_HAND;
			currentStatsJoint = cmb_jointList.selectedItem.data;

			cmb_jointList.addEventListener(Event.SELECT, jointSelectedHandler, false, 0, true);
			wnd_stats.x = (stage.stageWidth/2) - (wnd_stats.width/2);
			wnd_stats.y = stage.stageHeight - wnd_stats.height - 50;

			chk_rgbMirror.selected = kConfig.rgbMirrored;
			chk_depthMirror.selected = kConfig.depthMirrored;
			chk_skeletonMirror.selected = kConfig.skeletonMirrored;
		}

		private function jointSelectedHandler(event:Event):void {
			currentStatsJoint = cmb_jointList.selectedItem.data;
			wnd_stats.title = currentStatsJoint + " Position Stats";
		}

		private function getUIPanel(type:String):XML {
			var x:String = "txt_"+type+"X";
			var y:String = "txt_"+type+"Y";
			var z:String = "txt_"+type+"Z";
			var rx:String = "txt_"+type+"RelativeX";
			var ry:String = "txt_"+type+"RelativeY";
			var rz:String = "txt_"+type+"RelativeZ";

			var panel:XML =
			<Panel width="225">
				<VBox x = "5">
					<Label text={type.toUpperCase()}/>
					<HBox width="225" spacing="25">
						<VBox width="100">
							<HBox>
								<Label text="X: "/>
								<Text  id={x} height="15" width="75" text=""/>
							</HBox>
							<HBox>
								<Label text="Y: "/>
								<Text  id={y} height="15" width="75" text=""/>
							</HBox>
							<HBox>
								<Label text="Z: "/>
								<Text  id={z} height="15" width="75" text=""/>
							</HBox>
						</VBox>
						<VBox width="100">
							<HBox>
								<Label text="rX: "/>
								<Text  id={rx} height="15" width="75" text=""/>
							</HBox>
							<HBox>
								<Label text="rY: "/>
								<Text  id={ry} height="15" width="75" text=""/>
							</HBox>
							<HBox>
								<Label text="rZ: "/>
								<Text  id={rz} height="15" width="75" text=""/>
							</HBox>
						</VBox>
					</HBox>
				</VBox>
			</Panel>;
			return panel;
		}

		public function onChkClick(event:MouseEvent):void {
			switch(event.target){
				case chk_rgbMirror:
					kinect.setRGBMirror(chk_rgbMirror.selected);
					break;
				case chk_depthMirror:
					kinect.setDepthMirror(chk_depthMirror.selected);
					break;
				case chk_skeletonMirror:
					kinect.setSkeletonMirror(chk_skeletonMirror.selected);
					break;
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[BasicDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[BasicDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			cmb_jointList.removeEventListener(Event.SELECT, jointSelectedHandler);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if(kinect != null)
			{
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				kinect.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.stop();
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			rgbSkeletonContainer.graphics.clear();
			depthSkeletonContainer.graphics.clear();
			skeletonContainer.removeChildren();
			
			
			for each(var user:User in kinect.users)
			{
				if(user.hasSkeleton)
				{
					for each(var joint:SkeletonJoint in user.skeletonJoints)
					{
						if(joint.positionConfidence > .5)
						{
							rgbSkeletonContainer.graphics.beginFill(0xFF0000);
							rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 5);
							rgbSkeletonContainer.graphics.endFill();
							
							depthSkeletonContainer.graphics.beginFill(0xFF0000);
							depthSkeletonContainer.graphics.drawCircle(joint.depthPosition.x, joint.depthPosition.y, 5);
							depthSkeletonContainer.graphics.endFill();
							
							var color:uint = (joint.positionRelative.z / (KinectMaxDepthInFlash * 4)) * 255 << 16 | (1 - (joint.positionRelative.z / (KinectMaxDepthInFlash * 4))) * 255 << 8 | 0;

							var jointSprite:Sprite = createCircleForPosition(joint.positionRelative, color);
							skeletonContainer.addChild(jointSprite);
						}
					}

					if(currentStatsJoint){
						var statsJoint:SkeletonJoint =  user.getJointByName(currentStatsJoint);
						txt_worldX.text = statsJoint.position.x.toFixed(4);
						txt_worldY.text = statsJoint.position.y.toFixed(4);
						txt_worldZ.text = statsJoint.position.z.toFixed(4);

						txt_worldRelativeX.text = statsJoint.positionRelative.x.toFixed(4);
						txt_worldRelativeY.text = statsJoint.positionRelative.y.toFixed(4);
						txt_worldRelativeZ.text = statsJoint.positionRelative.z.toFixed(4);

						txt_rgbX.text = statsJoint.rgbPosition.x.toFixed(4);
						txt_rgbY.text = statsJoint.rgbPosition.y.toFixed(4);
						txt_rgbRelativeX.text = statsJoint.rgbRelativePosition.x.toFixed(4);
						txt_rgbRelativeY.text = statsJoint.rgbRelativePosition.y.toFixed(4);

						txt_depthX.text = statsJoint.depthPosition.x.toFixed(4);
						txt_depthY.text = statsJoint.depthPosition.y.toFixed(4);
						txt_depthRelativeX.text = statsJoint.depthRelativePosition.x.toFixed(4);
						txt_depthRelativeY.text = statsJoint.depthRelativePosition.y.toFixed(4);
					}
				}
				//user center position
				var userCenterSprite:Sprite = createCircleForPosition(user.positionRelative, 0xFF0000);
				skeletonContainer.addChild(userCenterSprite);
			}
		}
		
		private function createCircleForPosition(positionRelative:Vector3D, color:uint):Sprite
		{
			var xPos:Number = ((positionRelative.x + 1) * .5) * explicitWidth;
			var yPos:Number = ((positionRelative.y - 1) / -2) * explicitHeight;
			var zPos:Number = positionRelative.z * KinectMaxDepthInFlash;
			
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(color);
			circle.graphics.drawCircle(0, 0, 15);
			circle.graphics.endFill();
			circle.x = xPos;
			circle.y = yPos;
			circle.z = zPos;
			
			return circle;
		}
		
		protected function depthImageUpdateHandler(event:CameraImageEvent):void
		{
			depthBitmap.bitmapData = event.imageData;
			layout();
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
		}
		
		override protected function layout():void
		{
			if(depthBitmap != null)
			{
				depthBitmap.x = explicitWidth - depthBitmap.width;
				depthSkeletonContainer.x = depthBitmap.x;
			}
			if(root != null)
			{
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
		}
	}
}