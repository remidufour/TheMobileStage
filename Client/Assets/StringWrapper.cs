using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using System;

#if UNITY_3_4 || UNITY_3_3 || UNITY_3_2 || UNITY_3_1 || UNITY_3_0_0 || UNITY_3_0
#error Unity 3.4.x and older is not supported by this version of String. Please upgrade Unity.
#endif

public class StringWrapper
{
	[StructLayout(LayoutKind.Sequential)]
	public struct MarkerInfo
	{
		public Quaternion rotation;
		public Vector3 position;
		Vector3 _color;
		
		public uint imageID;
		public uint uniqueInstanceID;

		public Color color
		{
			get
			{
				return new Color(_color.x, _color.y, _color.z);
			}
		}
		
		public void DummyData()
		{
			imageID = 0;
			uniqueInstanceID = 0;
			_color = Vector3.one;
			position = new Vector3(0, 0, 2);
			rotation = new Quaternion(-0.5110371f, 0.8248347f, 0.06259407f, 0.233604f);
		}
	}
	
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
	public struct DeviceInfo
	{
		const int stringLength = 100;
		
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = stringLength)]
		public string name;
		
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = stringLength)]
		public string id;
		
		[MarshalAs(UnmanagedType.I1)]
		public bool isAvailable;
	}
	
	[StructLayout(LayoutKind.Sequential)]
	struct MarshalRect
	{
		public float x, y, width, height;
		
		public MarshalRect(Rect rect)
		{
			x = rect.x;
			y = rect.y;
			width = rect.width;
			height = rect.height;
		}
		
		public static implicit operator MarshalRect(Rect rect)
		{
			return new MarshalRect(rect);
		}
	}
	
	class MobileWrapper
	{
		[DllImport("__Internal")]
	    public static extern uint String_GetData([Out]MarkerInfo[] markerInfo, uint maxMarkerCount);
		
	    [DllImport("__Internal")]
	    public static extern void String_SetProjectionAndViewport([In]Matrix4x4 projectionMatrix, [In]MarshalRect normalizedViewport, int orientation, bool reorientIPhoneSplash);
		
	    [DllImport("__Internal", CharSet = CharSet.Unicode)]
		public static extern int String_LoadImageMarker([In, MarshalAs(UnmanagedType.LPStr)]string fileName, [In, MarshalAs(UnmanagedType.LPStr)]string extension);

	    [DllImport("__Internal")]
		public static extern void String_UnloadImageMarkers();

		[DllImport("__Internal", CharSet = CharSet.Unicode)] [return: MarshalAs(UnmanagedType.LPStr)]
		public static extern string String_InvokeGUIFunction([In, MarshalAs(UnmanagedType.LPStr)]string functionDescriptor, [In, MarshalAs(UnmanagedType.LPStr)]string[] parameters, int parameterCount);
		
	    [DllImport("__Internal")]
		public static extern void String_EnableAR(bool enable);		

	    [DllImport("__Internal")]
		public static extern void String_SetVideoTextureNames(uint first, uint second);

	    [DllImport("__Internal")]
		public static extern bool String_GetCurrentVideoTexture(out uint textureName, out Matrix4x4 viewToVideoTextureTransform);

	    [DllImport("__Internal")]
		public static extern float String_GetDeviceVerticalFOV();

	    // This is a dummy function to make sure you're linking against 
		// a compatible version of the String for Unity library.
		[DllImport("__Internal")]
		public static extern void String_Mobile_Library_Interface_Version_5();
	}

	class DesktopWrapper
	{
	    [DllImport("String", CharSet = CharSet.Unicode)]
	    public static extern bool InitTracker([MarshalAs(UnmanagedType.LPStr)]string deviceId, ref uint width, ref uint height, float verticalFOV);
	
	    [DllImport("String")]
	    public static extern void DeinitTracker();
	
	    [DllImport("String", CharSet = CharSet.Unicode)]
		public static extern int LoadImageMarker([MarshalAs(UnmanagedType.LPStr)]string fileName, [MarshalAs(UnmanagedType.LPStr)]string extension);
		
	    [DllImport("String")]
	    public static extern bool ProcessFrame(uint textureId, uint debugTextureId);
	
	    [DllImport("String")]
	    public static extern uint GetDataQuaternionBased([Out]MarkerInfo[] markerInfo, uint maxMarkerCount);

		[DllImport("String")]
	    public static extern bool IsNewFrameReady();
	
	    [DllImport("String")]
	    public static extern uint EnumerateDevices([Out]DeviceInfo[] deviceInfo, uint maxDeviceCount);

		[DllImport("String")]
		public static extern uint GetInterfaceVersion();
	}

	Texture2D[] videoTextures;
	Material videoMaterial;
	Mesh videoPlaneMesh;
	GameObject videoPlaneObject;

	static bool isMobile = (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer);
	static bool wasInstantiated = false;
	static object initLock = new object();

	bool wasInitialized = false;
	ScreenOrientation currentOrientation;
	
	Camera _camera;
	bool _reorientIPhoneSplash;
	bool _fullscreen;
	float _alignment;
	float _previewCamApproxVerticalFOV;
	
	const uint maxMarkerCount = 10;
	MarkerInfo[] markerInfo = new MarkerInfo[maxMarkerCount];
	uint markerCount = 0;

	uint previewWidth = 640, previewHeight = 480;
			
	void ApplyViewSettings()	
	{
		if (isMobile)
		{
			const float cameraAspectRatio = 4f / 3f;

			bool landscape = 
				Screen.orientation == ScreenOrientation.Landscape ||
				Screen.orientation == ScreenOrientation.LandscapeLeft ||
				Screen.orientation == ScreenOrientation.LandscapeRight;
	
			float aspectRatio = Screen.width / (float)Screen.height;
			float halfTan = Mathf.Tan(MobileWrapper.String_GetDeviceVerticalFOV() * Mathf.PI / 360f);
			
			if (landscape)
			{
				if (_fullscreen)
				{
					halfTan *= cameraAspectRatio / aspectRatio;
				}
			}
			else
			{
				halfTan *= cameraAspectRatio;
			}
			
			_camera.fieldOfView = Mathf.Atan(halfTan) * 360f / Mathf.PI;
			
			float orientedAlignment = _alignment;
			
			if (Screen.orientation == ScreenOrientation.Portrait || Screen.orientation == ScreenOrientation.LandscapeRight)
			{
				orientedAlignment = 1f - orientedAlignment;
			}
			
			if (_fullscreen)
			{
				_camera.rect = new Rect(0, 0, 1, 1);
			}
			else
			{
				if (landscape)
				{
					float coverage = cameraAspectRatio / aspectRatio;
				
					_camera.rect = new Rect((1 - coverage) * orientedAlignment, 0, coverage, 1);
				}
				else
				{
					float coverage = cameraAspectRatio * aspectRatio;
				
					_camera.rect = new Rect(0, (1 - coverage) * orientedAlignment, 1, coverage);
				}
			}
		}
		else
		{
			_camera.fieldOfView = _previewCamApproxVerticalFOV;
			_camera.rect = new Rect(0, 0, 1, 1);
		}
	}

	void CreateVideoMaterial() 
	{
        videoMaterial = new Material(
			"Shader \"VideoFrameShader\" {" +
			"Properties { _MainTex (\"Base (RGB)\", 2D) = \"white\" {} }" +
            "SubShader { Pass {" +
            "    Blend Off" +
            "    ZTest Always ZWrite Off Cull Off Lighting Off Fog { Mode Off }" +
			"    SetTexture[_MainTex] { combine texture }" +
			"} } }" );
        videoMaterial.hideFlags = HideFlags.HideAndDontSave;
        videoMaterial.shader.hideFlags = HideFlags.HideAndDontSave;
		
		videoTextures = new Texture2D[] {new Texture2D(1, 1, TextureFormat.ARGB32, false)};
		videoTextures[0].wrapMode = TextureWrapMode.Clamp;
		videoMaterial.SetTexture("_MainTex", videoTextures[0]);
		videoMaterial.renderQueue = 0;
	}
	
	void CreateVideoMesh()
	{
		videoPlaneMesh = new Mesh();
		
		videoPlaneMesh.vertices = new Vector3[] {
			new Vector3(-1, -1, 0),
			new Vector3(1, -1, 0),
			new Vector3(-1, 1, 0),
			new Vector3(1, 1, 0)};
		
		videoPlaneMesh.uv = new Vector2[] {
			new Vector2(0, 1),
			new Vector2(1, 1),
			new Vector2(0, 0),
			new Vector2(1, 0)};
		
		videoPlaneMesh.SetTriangleStrip(new int[] {0, 1, 2, 3}, 0);
	}
	
	void InitializePreviewPlugin(string preferredDeviceName, Camera camera)
	{
		// Test library compatibility
		if (DesktopWrapper.GetInterfaceVersion() != 3)
		{
			Debug.LogError("You appear to be using incompatible versions of StringWrapper.cs and String.bundle; Please make sure you're using the latest versions of both.");
			
			return;
		}

		// Enumerate devices
		uint maxDeviceCount = 10;
		DeviceInfo[] deviceInfo = new DeviceInfo[maxDeviceCount];
		
		uint deviceCount = DesktopWrapper.EnumerateDevices(deviceInfo, maxDeviceCount);
		
		for (int i = 0; i < deviceCount; i++)
		{
			Debug.Log("Found camera \"" + deviceInfo[i].name + "\" (" + (deviceInfo[i].isAvailable ? "available for use.)" : "not available for use.)"));
		}
		
		if (deviceCount > 0)
		{
			uint i;
			
			for (i = 0; i < deviceCount; i++)
			{
				if (deviceInfo[i].name == preferredDeviceName) break;
			}
			
			if (i < deviceCount)
			{
				Debug.Log("Capturing video from preferred device \"" + deviceInfo[i].name + "\".");
			}
			else
			{
				i = 0;

				if (preferredDeviceName != null)
				{
					Debug.Log("Preferred device was not found. Using \"" + deviceInfo[i].name + "\".");
				}
				else
				{
					Debug.Log("Capturing video from device \"" + deviceInfo[i].name + "\".");
				}
			}
			
			if (DesktopWrapper.InitTracker(deviceInfo[i].id, ref previewWidth, ref previewHeight, _previewCamApproxVerticalFOV))
			{
				CreateVideoMaterial();
				CreateVideoMesh();
				
				float scale = camera.farClipPlane * 0.99f;
				
				float verticalScale = scale * Mathf.Tan(_previewCamApproxVerticalFOV * Mathf.PI / 360f);
				
				videoPlaneObject = new GameObject("Video Plane", new Type[] {typeof(MeshRenderer), typeof(MeshFilter)});
				videoPlaneObject.hideFlags = HideFlags.HideAndDontSave;
				videoPlaneObject.active = false;
				
				videoPlaneObject.renderer.material = videoMaterial;
				
				MeshFilter meshFilter = (MeshFilter)videoPlaneObject.GetComponent(typeof(MeshFilter));
				meshFilter.sharedMesh = videoPlaneMesh;
				
				videoPlaneObject.transform.parent = camera.transform;
				videoPlaneObject.transform.localPosition = new Vector3(0, 0, scale);
				videoPlaneObject.transform.localRotation = Quaternion.identity;
				videoPlaneObject.transform.localScale = new Vector3(verticalScale * (float)previewWidth / previewHeight, verticalScale, 1);
				
				wasInitialized = true;
			}
			else
			{
				Debug.Log("Failed to initialize String.");
			}
		}
		else
		{
			Debug.LogError("No devices suitable for video capture were detected.");
		}
	}
	
	public StringWrapper(string previewCamName, Camera camera, bool reorientIPhoneSplash, bool fullscreen, float alignment) : 
		this(previewCamName, 36.3f, camera, reorientIPhoneSplash, fullscreen, alignment) {}
	
	public StringWrapper(string previewCamName, float previewCamApproxVerticalFOV, Camera camera, bool reorientIPhoneSplash, bool fullscreen, float alignment)
	{
		_camera = camera;
		_reorientIPhoneSplash = reorientIPhoneSplash;
		_fullscreen = fullscreen;
		_alignment = alignment;
		_previewCamApproxVerticalFOV = previewCamApproxVerticalFOV;
		
		ApplyViewSettings();
		
		lock(initLock)
		{
			for (uint i = 0; wasInstantiated && i < 10; i++)
			{
				System.Threading.Monitor.Exit(initLock);
				System.Threading.Thread.Sleep(500);
				System.Threading.Monitor.Enter(initLock);
			}
			
			if (wasInstantiated)
				throw new System.InvalidOperationException("StringWrapper was already instantiated. Only one instance of StringWrapper may exist at any given time.");
			
			wasInstantiated = true;
			
			if (isMobile)
			{
				camera.clearFlags = CameraClearFlags.Nothing;
	
				MobileWrapper.String_UnloadImageMarkers();
					
				videoTextures = new Texture2D[] {new Texture2D(1, 1, TextureFormat.ARGB32, false), new Texture2D(1, 1, TextureFormat.ARGB32, false)};
				videoTextures[0].wrapMode = TextureWrapMode.Clamp;
				videoTextures[1].wrapMode = TextureWrapMode.Clamp;
				
				MobileWrapper.String_SetVideoTextureNames((uint)videoTextures[0].GetNativeTextureID(), (uint)videoTextures[1].GetNativeTextureID());

				MobileWrapper.String_SetProjectionAndViewport(camera.projectionMatrix, camera.rect, (int)Screen.orientation, reorientIPhoneSplash);
				
				MobileWrapper.String_EnableAR(true);
				
				wasInitialized = true;
			}
			else
			{
				try
				{
					InitializePreviewPlugin(previewCamName, camera);
				}
				catch 
				{
					Debug.LogWarning("Couldn't initialize String preview plugin. StringWrapper will return placeholder data. " +
						"If you're *not* running Unity Pro, your editor doesn't support plugins, and you can safely ignore this message. You will still be able to deploy to iOS. " +
						"If you *are* running Unity Pro, please make sure you've added String.bundle from the SDK to your project.");
				}
			}
		}
	}
	
	public uint Update()
	{
		if (wasInitialized)
		{
			if (isMobile)
			{
				if (Screen.orientation != currentOrientation && Time.frameCount > 1)
				{
					ApplyViewSettings();
					
					MobileWrapper.String_SetProjectionAndViewport(_camera.projectionMatrix, _camera.rect, (int)(currentOrientation = Screen.orientation), _reorientIPhoneSplash);
				}
		
				markerCount = MobileWrapper.String_GetData(markerInfo, maxMarkerCount);
			}
			else
			{
				if (DesktopWrapper.IsNewFrameReady())
				{
					DesktopWrapper.ProcessFrame((uint)videoTextures[0].GetNativeTextureID(), 0);
					markerCount = DesktopWrapper.GetDataQuaternionBased(markerInfo, maxMarkerCount);
					videoPlaneObject.active = true;
				}
			}
		}
		else
		{
			// Write dummy output data
			markerCount = 1;
			markerInfo[0].DummyData();
		}
		
		return markerCount;
	}
	
	public int LoadImageMarker(string fileName, string extension)
	{
		if (wasInitialized)
		{
			if (isMobile)
			{
				return MobileWrapper.String_LoadImageMarker("Data/Raw/" + fileName, extension);
			}
			else
			{
				string path = Application.dataPath + "/StreamingAssets/" + fileName;
				
				int id = DesktopWrapper.LoadImageMarker(path, extension);
				
				if (id < 0)
				{
					Debug.LogWarning("Failed to load marker image \"" + path + "." + extension + "\"");
				}
				else
				{
					Debug.Log("Loaded marker image \"" + path + "." + extension + "\"");
				}
				
				return id;
			}
		}
		else
		{
			return -1;
		}
	}
	
	public MarkerInfo GetDetectedMarkerInfo(uint markerIndex)
	{
		if (markerIndex < 0 || markerIndex > markerCount) throw new System.ArgumentException("Marker index out of range.");
		
		return markerInfo[markerIndex];
	}
	
	public Texture2D GetCurrentVideoTexture(out Matrix4x4 viewToVideoTextureTransform)
	{
		if (isMobile)
		{
			uint textureName = 0;

			if (MobileWrapper.String_GetCurrentVideoTexture(out textureName, out viewToVideoTextureTransform))
			{
				if (textureName == (uint)videoTextures[0].GetNativeTextureID())
					return videoTextures[0];
				else if (textureName == (uint)videoTextures[1].GetNativeTextureID())
					return videoTextures[1];
				else
					return null;
			}
			else
			{
				Debug.LogError("Failed to get current video texture. This feature is only available in Developer, Pro and Campaign builds of the String SDK.");
					
				return null;
			}
		}
		else
		{
			viewToVideoTextureTransform = Matrix4x4.TRS(
				new Vector3(0.5f, 0.5f, 0), Quaternion.identity, 
				new Vector3(0.5f * ((float)Screen.width / Screen.height) * (float)previewHeight / previewWidth, -0.5f, 0)) * _camera.projectionMatrix;
			
			return videoTextures[0];
		}
	}
	
	public static string InvokeGUIFunction(string descriptor, string[] parameters)
	{
		if (isMobile)
		{
			return MobileWrapper.String_InvokeGUIFunction(descriptor, parameters, parameters != null ? parameters.Length : 0);
		}
		
		return null;
	}

	~StringWrapper()
	{
		lock(initLock)
		{
			if (wasInitialized)
			{
				if (isMobile)
				{
					MobileWrapper.String_EnableAR(false);
				}
				else
				{
					DesktopWrapper.DeinitTracker();
				}
			}
			
			wasInstantiated = false;
		}
	}
}