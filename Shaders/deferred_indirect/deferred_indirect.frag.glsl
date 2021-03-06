#version 450

#ifdef GL_ES
precision mediump float;
#endif

#include "../compiled.glsl"
#include "../std/gbuffer.glsl"
#include "../std/math.glsl"
#include "../std/brdf.glsl"
#ifdef _Irr
	#include "../std/shirr.glsl"
#endif
#ifdef _VoxelGI
	#include "../std/conetrace.glsl"
#endif

uniform sampler2D gbufferD;
uniform sampler2D gbuffer0;
uniform sampler2D gbuffer1;

#ifdef _VoxelGI
	//!uniform sampler3D voxels;
#endif

uniform float envmapStrength;
#ifdef _Irr
	//!uniform vec4 shirr[7];
#endif
#ifdef _Rad
	uniform sampler2D senvmapRadiance;
	uniform sampler2D senvmapBrdf;
	uniform int envmapNumMipmaps;
#endif

#ifdef _SSAO
	uniform sampler2D ssaotex;
#endif

#ifdef _Rad
	uniform vec3 eye;
	uniform vec3 eyeLook;
#endif

in vec2 texCoord;
#ifdef _Rad
	in vec3 viewRay;
#endif
out vec4 fragColor;

void main() {
	vec4 g0 = texture(gbuffer0, texCoord); // Normal.xy, metallic/roughness, occlusion
	
	vec3 n;
	n.z = 1.0 - abs(g0.x) - abs(g0.y);
	n.xy = n.z >= 0.0 ? g0.xy : octahedronWrap(g0.xy);
	n = normalize(n);

	vec2 metrough = unpackFloat(g0.b);

	vec4 g1 = texture(gbuffer1, texCoord); // Basecolor.rgb, 
	vec3 albedo = surfaceAlbedo(g1.rgb, metrough.x); // g1.rgb - basecolor

#ifdef _Rad
	float depth = texture(gbufferD, texCoord).r * 2.0 - 1.0;
	vec3 p = getPos(eye, eyeLook, viewRay, depth);
	vec3 v = normalize(eye - p.xyz);

	float dotNV = max(dot(n, v), 0.0);
	vec3 f0 = surfaceF0(g1.rgb, metrough.x);
	vec2 envBRDF = texture(senvmapBrdf, vec2(metrough.y, 1.0 - dotNV)).xy;
#endif

#ifdef _VoxelGI
	vec4 indirectDiffuse = indirectDiffuseLight(n, p / voxelgiDimensions.x);
	
	vec3 reflectWorld = reflect(-v, n);
	vec3 indirectSpecular = traceSpecularVoxelCone(p / voxelgiDimensions.x, reflectWorld, n, metrough.y * 10.0);
	indirectSpecular *= f0 * envBRDF.x + envBRDF.y;

	// fragColor.rgb = indirectDiffuse.rgb * 60.0 * albedo + indirectSpecular;
	fragColor.rgb = max(vec3(1.0 - (indirectDiffuse.a / 2.0)), 0.05) * albedo;
	// fragColor.rgb *= 1.0 - (indirectDiffuse.a / 2.0); // Occ
	fragColor.rgb *= texture(ssaotex, texCoord).r * 0.5 + 0.5;

	// if (opacity < 1.0) fragColor.rgb = mix(indirectRefractiveLight(-v), fragColor.rgb); // Transparency
	return;
#endif
	
	// Envmap
#ifdef _Irr
	vec3 envl = shIrradiance(n, 2.2) / PI;
#else
	vec3 envl = vec3(1.0);
#endif

#ifdef _Rad
	vec3 reflectionWorld = reflect(-v, n);
	float lod = getMipFromRoughness(metrough.y, envmapNumMipmaps);
	vec3 prefilteredColor = textureLod(senvmapRadiance, envMapEquirect(reflectionWorld), lod).rgb;
#endif

#ifdef _EnvLDR
	envl.rgb = pow(envl.rgb, vec3(2.2));
	#ifdef _Rad
		prefilteredColor = pow(prefilteredColor, vec3(2.2));
	#endif
#endif

	envl.rgb *= albedo;
	
#ifdef _Rad // Indirect specular
	envl.rgb += prefilteredColor * (f0 * envBRDF.x + envBRDF.y);
#endif

	envl.rgb *= envmapStrength * g0.a; // Occlusion

#ifdef _SSAO
	envl.rgb *= texture(ssaotex, texCoord).r; // SSAO
#endif

#ifdef _VoxelGI
	float m = (fragColor.r + fragColor.g + fragColor.b) / 3.0;
	fragColor.rgb += (envl / 5.0) * m;
#else
	fragColor.rgb = envl;
#endif
}
