//
//  Copyright (C) 2013 Remi Dufour & Mike Dai Wang
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#ifndef _XML_HELPER_H_
# define _XML_HELPER_H_

// Use TinyXML from another solution
# include <tinyxml.h>

// Default XML filename
# define DEFAULT_FILENAME "input.xml"

// An XML element
typedef TiXmlElement * Element;

// An invalid XML element
# define InvalidElement (Element)NULL

// Success
# define XML_SUCCESS (int)TIXML_SUCCESS

class XMLHelper
{
public:
	// Constructor, destructor
	XMLHelper(void);
	~XMLHelper(void);

	// Loading and unloading functions
	bool Load(const char *filename);
	inline bool Load(void)
    {
        return Load(DEFAULT_FILENAME);
    }

	void Release(void);
	Element GetRootElement(void);
	
	// Navigating functions
	Element FirstChildElement(Element element);
	Element NextElement(Element element);

	// Access functions
	static int QueryIntValue(Element element, const char *name, int *value);
	static int QueryUIntValue(Element element, const char *name, unsigned int *value);
	static int QueryFloatValue(Element element, const char *name, float *value);
	static const char* GetValue(Element element);

	// Helper function
	static Element SeekElement(Element element, const char *name);

	class XMLHelperElementWrapper
	{
		TiXmlElement* pelement;

	public:

		XMLHelperElementWrapper()
			:pelement(0)
		{
        }

		XMLHelperElementWrapper(TiXmlElement* elem)
			:pelement(elem)
		{
        }

		bool IsValid(void)
		{
			return pelement!=0;
		}

		XMLHelperElementWrapper GetElement(const char *name);

		float GetFloat(const char *attribname);

		int GetInt(const char *attribname);

		unsigned int GetUInt(const char *attribname);

		Element GetElementNode(void)
		{
			return pelement;
		}

		const char* GetValue(void)
		{
			return XMLHelper::GetValue(pelement);
		}

		const char * GetString(const char *attribute);

		void GetInt2(const char *attribute, int &value1, int &value2);
	};

	XMLHelperElementWrapper invalidelement;
	
	XMLHelperElementWrapper GetElement(const char *name);
	XMLHelperElementWrapper GetElement(Element element);

private:

	// Tiny XML is only present here
	TiXmlDocument *mDoc;
};


extern XMLHelper xml;

extern XMLHelper calibxml;

#endif  // _XML_HELPER_H_