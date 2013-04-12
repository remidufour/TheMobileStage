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

#include <iostream>

#include "XMLHelper.h"

using namespace std;

XMLHelper::XMLHelper(void)
	: mDoc(NULL)
{
}

XMLHelper::~XMLHelper(void)
{
}

bool XMLHelper::Load(const char *filename)
{
    if (filename == NULL)
    {
        cerr << "Filename is NULL." << endl;
        return false;
    }

	TiXmlDocument *doc = new TiXmlDocument();

	if (doc == NULL)
	{
		cerr << "Memory allocation failure." << endl;
		return false;
	}

	if (doc->LoadFile(filename, TIXML_DEFAULT_ENCODING) == false)
	{
		cerr << "Failed to load XML file: " << doc->ErrorDesc() << endl;
		return false;
	}

	mDoc = doc;
	return true;
}

void XMLHelper::Release(void)
{
	delete[] mDoc;
}

Element XMLHelper::GetRootElement(void)
{
	if (mDoc == NULL)
		return InvalidElement;

	return mDoc->FirstChildElement();
}

Element XMLHelper::FirstChildElement(Element element)
{
	if (mDoc == NULL || element == NULL)
		return InvalidElement;

	return element->FirstChildElement();
}

Element XMLHelper::NextElement(Element element)
{
	if (mDoc == NULL || element == NULL)
		return InvalidElement;

	return element->NextSiblingElement();
}

const char* XMLHelper::GetValue(Element element)
{
	if (element == NULL)
		return NULL;

	return element->GetText();
}

Element XMLHelper::SeekElement(Element element, const char *name)
{
	if (element == NULL)
		return InvalidElement;

	return element->FirstChildElement(name);
}

int XMLHelper::QueryIntValue(Element element, const char *name, int *value)
{
	if (element == NULL)
		return -1;

	return element->QueryIntAttribute(name, value);
}

int XMLHelper::QueryUIntValue(Element element, const char *name, unsigned int *value)
{
	if (element == NULL)
		return -1;

	int signedValue = 0;
	int ret = element->QueryIntAttribute(name, &signedValue);

	if (ret != TIXML_SUCCESS)
		return ret;

	if (signedValue < 0)
		*value = 0;
	else
		*value = signedValue;

	return ret;
}

int XMLHelper::QueryFloatValue(Element element, const char *name, float *value)
{
	if (element == NULL)
		return -1;

	return element->QueryFloatAttribute(name, value);
}


XMLHelper::XMLHelperElementWrapper XMLHelper::GetElement(const char *name)
{
	TiXmlElement* elem = GetRootElement();

	if(elem == NULL)
        return invalidelement;

	TiXmlElement* subelem = SeekElement(elem, name);

	if(subelem == NULL)
        return invalidelement;

	return XMLHelperElementWrapper(subelem);
}

XMLHelper::XMLHelperElementWrapper XMLHelper::GetElement(Element element)
{
	return XMLHelperElementWrapper(element);
}

XMLHelper::XMLHelperElementWrapper XMLHelper::XMLHelperElementWrapper::GetElement(const char *name)
{
    // I am invalid, so return a copy of myself.
	if (pelement == 0)
        return (*this);

	return SeekElement(pelement, name);
}

float XMLHelper::XMLHelperElementWrapper::GetFloat(const char *attribname)
{
	if (pelement == 0)
        return 0;

	float ret = 0;
	XMLHelper::QueryFloatValue(pelement, attribname, &ret);

	return ret;
}

int XMLHelper::XMLHelperElementWrapper::GetInt(const char *attribname)
{
	if (pelement == 0)
        return 0;

	int ret = 0;
	XMLHelper::QueryIntValue(pelement, attribname, &ret);

	return ret;
}

unsigned int XMLHelper::XMLHelperElementWrapper::GetUInt(const char *attribname)
{
    if (pelement == 0)
        return 0;

    unsigned int ret = 0;
    XMLHelper::QueryUIntValue(pelement, attribname, &ret);

    return ret;
}

const char * XMLHelper::XMLHelperElementWrapper::GetString(const char *attribute)
{
	if (pelement == 0)
        return NULL;

	const char *pchar = pelement->Attribute(attribute);

	if (pchar)
		return pchar;

	return NULL;
}

void XMLHelper::XMLHelperElementWrapper::GetInt2(const char *attribute, int &value1, int &value2)
{
	if (pelement == 0)
        return;

	const char* pchar = pelement->Attribute(attribute);

	if (pchar)
	{
        /* TODO: Fix */
#if 0
		_s str(pchar);
		_vector<_s> vval = str.split(' ');

		if (vval.size() != 2)
            return _int2(0, 0);

		return _int2(vval[0].toint(), vval[1].toint());
#endif
	}

    value1 = 0;
    value2 = 0;
	return;
}