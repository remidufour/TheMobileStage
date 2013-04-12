using UnityEngine;
using System.Collections;

public class ContentCentricARManager : MonoBehaviour 
{
	public GameObject[] markerObjects;
	public bool fullscreen = false;
	public float alignment = 0.5f;
	public bool reorientIPhoneSplash = false;
	public string previewCamName;
	public float previewCamApproxVerticalFOV = 36.3f;
	float lastSpottedTime;
	
	StringWrapper stringWrapper;
	
	void Awake() 
	{
		// Initialize String
		stringWrapper = new StringWrapper(previewCamName, previewCamApproxVerticalFOV, camera, reorientIPhoneSplash, fullscreen, alignment);

		// Load some image targets
		stringWrapper.LoadImageMarker("Marker 1", "png");
	}
	
	void Update() 
	{
		// Perform marker image tracking
		uint markerCount = stringWrapper.Update();
		
		// Handle detected markers
		for (uint i = 0; i < markerCount; i++)
		{
			// Fetch tracker data for this marker
			StringWrapper.MarkerInfo markerInfo = stringWrapper.GetDetectedMarkerInfo(i);
			
			if (markerInfo.imageID < markerObjects.Length)
			{
				// Orient the camera according to the marker
				transform.parent = markerObjects[markerInfo.imageID].transform;

				transform.localRotation = Quaternion.Inverse(markerInfo.rotation);
				transform.localPosition = transform.localRotation * -markerInfo.position;
				
				lastSpottedTime = Time.time;
				
				break;
			}
		}
		
		// Marker not spotted? Point camera away
		if (lastSpottedTime != Time.time)
		{
			transform.localPosition = new Vector3(1000000, 0, 0);
			transform.localRotation = Quaternion.identity;
		}
	}
}
