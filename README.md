# Contaminant-Cross-Prediction
GUI for glass contaminant cross prediction, part of work done at Cheyney design and development.

#Theorum
If impurity is detected and viewed from two camera projections, its projection from the third camera can be predicted exactly, 
if only one camera projection is available,
there will be infinite numbers of positions which the contaminant can take on other camera projections.

\begin{eqnarray}
b=\dfrac{tan\beta(c-r)-rsec\beta+tan\alpha(a-\dfrac{r}{sin\alpha}+r)}{tan\alpha+tan\beta} \label{eq.3}
\end{eqnarray}
Both angles $\alpha$ and $\beta$ can be determined from the images where $A$ and $C$ are the full projected length of the images on projector 2 and 3.
\begin{eqnarray}
\alpha&=&\arcsin(\dfrac{2r}{A}) \label{eq.angle1}\\
\beta&=&\arcsin(\dfrac{2r}{C}) \label{eq.angle2}
\end{eqnarray}
