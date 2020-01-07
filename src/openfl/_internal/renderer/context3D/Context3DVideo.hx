package openfl._internal.renderer.context3D;

#if openfl_gl
import openfl._internal.bindings.gl.GL;
import openfl._internal.bindings.typedarray.Float32Array;
import openfl._internal.bindings.typedarray.UInt16Array;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.media.Video;
#if gl_stats
import openfl._internal.renderer.context3D.stats.Context3DStats;
import openfl._internal.renderer.context3D.stats.DrawCallContext;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.Shader)
@:access(openfl.geom.ColorTransform)
@:access(openfl.media.Video)
@:access(openfl.net.NetStream)
@SuppressWarnings("checkstyle:FieldDocComment")
class Context3DVideo
{
	private static inline var VERTEX_BUFFER_STRIDE:Int = 5;

	private static var __textureSizeValue:Array<Float> = [0, 0.];

	private static function getIndexBuffer(video:Video, context:Context3D):IndexBuffer3D
	{
		#if (lime && openfl_gl)
		var gl = context.gl;

		if (video.__renderData.indexBuffer == null || video.__renderData.indexBufferContext != context.__context)
		{
			// TODO: Use shared buffer on context

			video.__renderData.indexBufferData = new UInt16Array(6);
			video.__renderData.indexBufferData[0] = 0;
			video.__renderData.indexBufferData[1] = 1;
			video.__renderData.indexBufferData[2] = 2;
			video.__renderData.indexBufferData[3] = 2;
			video.__renderData.indexBufferData[4] = 1;
			video.__renderData.indexBufferData[5] = 3;

			video.__renderData.indexBufferContext = context.__context;
			video.__renderData.indexBuffer = context.createIndexBuffer(6);
			video.__renderData.indexBuffer.uploadFromTypedArray(video.__renderData.indexBufferData);
		}

		return video.__renderData.indexBuffer;
		#else
		return null;
		#end
	}

	private static function getTexture(video:Video, context:Context3D):RectangleTexture
	{
		#if openfl_html5
		if (video.__stream == null || @:privateAccess video.__stream.__backend.video == null) return null;

		var gl = context.__context.webgl;
		var internalFormat = gl.RGBA;
		var format = gl.RGBA;

		if (@:privateAccess !video.__stream.__backend.closed && @:privateAccess video.__stream.__backend.video.currentTime != video.__renderData.textureTime)
		{
			if (video.__renderData.texture == null)
			{
				video.__renderData.texture = context.createRectangleTexture(@:privateAccess video.__stream.__backend.video.videoWidth, @:privateAccess video.__stream.__backend.video.videoHeight, BGRA, false);
			}

			context.__bindGLTexture2D(video.__renderData.texture.__textureID);
			gl.texImage2D(gl.TEXTURE_2D, 0, internalFormat, format, gl.UNSIGNED_BYTE, @:privateAccess video.__stream.__backend.video);

			video.__renderData.textureTime = @:privateAccess video.__stream.__backend.video.currentTime;
		}

		return cast video.__renderData.texture;
		#else
		return null;
		#end
	}

	private static function getVertexBuffer(video:Video, context:Context3D):VertexBuffer3D
	{
		#if (lime && openfl_gl)
		var gl = context.gl;

		if (video.__renderData.vertexBuffer == null || video.__renderData.vertexBufferContext != context.__context)
		{
			#if openfl_power_of_two
			var newWidth = 1;
			var newHeight = 1;

			while (newWidth < width)
			{
				newWidth <<= 1;
			}

			while (newHeight < height)
			{
				newHeight <<= 1;
			}

			var uvWidth = width / newWidth;
			var uvHeight = height / newHeight;
			#else
			var uvWidth = 1;
			var uvHeight = 1;
			#end

			video.__renderData.vertexBufferData = new Float32Array(VERTEX_BUFFER_STRIDE * 4);

			video.__renderData.vertexBufferData[0] = video.width;
			video.__renderData.vertexBufferData[1] = video.height;
			video.__renderData.vertexBufferData[3] = uvWidth;
			video.__renderData.vertexBufferData[4] = uvHeight;
			video.__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE + 1] = video.height;
			video.__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE + 4] = uvHeight;
			video.__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE * 2] = video.width;
			video.__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE * 2 + 3] = uvWidth;

			video.__renderData.vertexBufferContext = context.__context;
			video.__renderData.vertexBuffer = context.createVertexBuffer(3, VERTEX_BUFFER_STRIDE);
			video.__renderData.vertexBuffer.uploadFromTypedArray(video.__renderData.vertexBufferData);
		}

		return video.__renderData.vertexBuffer;
		#else
		return null;
		#end
	}

	public static function render(video:Video, renderer:Context3DRenderer):Void
	{
		#if openfl_html5
		if (!video.__renderable || video.__worldAlpha <= 0 || video.__stream == null) return;

		if (@:privateAccess video.__stream.__backend.video != null)
		{
			var context = renderer.context3D;
			var gl = context.gl;

			var texture = getTexture(video, context);
			if (texture == null) return;

			renderer.__setBlendMode(video.__worldBlendMode);
			renderer.__pushMaskObject(video);
			// renderer.filterManager.pushObject (video);

			var shader = renderer.__initDisplayShader(cast video.__worldShader);
			renderer.setShader(shader);

			// TODO: Support ShaderInput<Video>
			renderer.applyBitmapData(null, true, false);
			// context.__bindGLTexture2D (getTexture(video, context));
			// shader.uImage0.input = bitmap.__bitmapData;
			// shader.uImage0.smoothing = renderer.__allowSmoothing && (bitmap.smoothing || renderer.__upscaled);
			renderer.applyMatrix(renderer.__getMatrix(video.__renderTransform, AUTO));
			renderer.applyAlpha(renderer.__getAlpha(video.__worldAlpha));
			renderer.applyColorTransform(video.__worldColorTransform);

			if (shader.__textureSize != null)
			{
				__textureSizeValue[0] = (video.__stream != null) ? @:privateAccess video.__stream.__backend.video.videoWidth : 0;
				__textureSizeValue[1] = (video.__stream != null) ? @:privateAccess video.__stream.__backend.video.videoHeight : 0;
				shader.__textureSize.value = __textureSizeValue;
			}

			renderer.updateShader();

			context.setTextureAt(0, getTexture(video, context));
			context.__flushGLTextures();
			gl.uniform1i(shader.__texture.index, 0);

			if (video.smoothing)
			{
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			}
			else
			{
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
			}

			var vertexBuffer = getVertexBuffer(video, context);
			if (shader.__position != null) context.setVertexBufferAt(shader.__position.index, vertexBuffer, 0, FLOAT_3);
			if (shader.__textureCoord != null) context.setVertexBufferAt(shader.__textureCoord.index, vertexBuffer, 3, FLOAT_2);
			var indexBuffer = getIndexBuffer(video, context);
			context.drawTriangles(indexBuffer);

			#if gl_stats
			Context3DStats.incrementDrawCall(DrawCallContext.STAGE);
			#end

			renderer.__clearShader();

			// renderer.filterManager.popObject (video);
			renderer.__popMaskObject(video);
		}
		#end
	}

	public static function renderMask(video:Video, renderer:Context3DRenderer):Void
	{
		#if openfl_html5
		if (video.__stream == null) return;

		if (@:privateAccess video.__stream.__backend.video != null)
		{
			var context = renderer.context3D;
			var gl = context.gl;

			var shader = renderer.__maskShader;
			renderer.setShader(shader);
			renderer.applyBitmapData(Context3DMaskShader.opaqueBitmapData, true);
			renderer.applyMatrix(renderer.__getMatrix(video.__renderTransform, AUTO));
			renderer.updateShader();

			var vertexBuffer = getVertexBuffer(video, context);
			if (shader.__position != null) context.setVertexBufferAt(shader.__position.index, vertexBuffer, 0, FLOAT_3);
			if (shader.__textureCoord != null) context.setVertexBufferAt(shader.__textureCoord.index, vertexBuffer, 3, FLOAT_2);
			var indexBuffer = getIndexBuffer(video, context);
			context.drawTriangles(indexBuffer);

			#if gl_stats
			Context3DStats.incrementDrawCall(DrawCallContext.STAGE);
			#end

			renderer.__clearShader();
		}
		#end
	}
}
#end
